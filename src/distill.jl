#
# Distill functions for extracting and transforming Epigraf data
#

"""
    distill_articles(df::DataFrame, cols::Vector{String} = String[];
                     section_type::Union{Nothing, String} = nothing,
                     section_cols::Vector{String} = String[],
                     item_type::Union{Nothing, String} = nothing,
                     item_cols::Vector{String} = String[],
                     property_cols::Vector{String} = String[])

Get articles with joined section, item, and property data.

# Arguments
- `df`: A RAM DataFrame.
- `cols`: Article columns to include.
- `section_type`: Section types to join. The result contains only items within sections of the given type.
                 Set to `nothing` to get all items.
- `section_cols`: Columns to join from the sections.
- `item_type`: Item types to join.
- `item_cols`: Columns to join from the items.
- `property_cols`: Columns to join from the properties.

# Returns
- A DataFrame with articles and joined data.
"""
function distill_articles(df::DataFrame, cols::Vector{String} = String[];
                         section_type::Union{Nothing, String} = nothing,
                         section_cols::Vector{String} = String[],
                         item_type::Union{Nothing, String} = nothing,
                         item_cols::Vector{String} = String[],
                         property_cols::Vector{String} = String[])
    # Extract articles    
    cases = subset(df, :table => ByRow(isequal("articles")))
    if !isempty(cols)
        select!(cases, ["id", "type", "norm_iri", cols...])
    else
        select!(cases, ["id", "type", "norm_iri"])
    end
    cases = unique(cases)

    extract_cols = String[]
    if !isempty(section_cols)
        extract_cols = vcat(extract_cols, ["sections_" * c for c in section_cols])
    end
    if !isempty(item_cols)
        extract_cols = vcat(extract_cols, ["items_" * c for c in item_cols])
    end
    if !isempty(property_cols)
        extract_cols = vcat(extract_cols, ["properties_" * c for c in property_cols])
    end

    if !isempty(extract_cols)
        # Extract items
        items = epi_extract_long(df, "items", item_type)

        if !isempty(property_cols)
            props = epi_extract_long(df, "properties")
            if nrow(props) > 0 && nrow(items) > 0
                # Join items with properties
                items = leftjoin(items, props, on = :items_property => :properties_id)
            end
        end

        if !isempty(section_cols)
            sections = epi_extract_long(df, "sections", section_type)
            if nrow(sections) > 0 && nrow(items) > 0
                items = innerjoin(sections, items, on = :sections_id => :items_sections_id)
            end
        end

        # Select only needed columns        
        missing_cols = setdiff(extract_cols, names(items))
        if !isempty(missing_cols)
            @warn "Columns not in data frame" missing_cols
        end
        items_cols = vcat(["items_articles_id"], intersect(names(items), extract_cols))
        select!(items, items_cols)

        # Replace HTML entities
        for col in extract_cols
            if col in names(items)
                items[!, col] = replace.(string.(items[!, col]), "&amp;" => "&")
                items[!, col] = replace.(string.(items[!, col]), "&x2f;" => "&")
            end
        end

        # Join with cases
        cases = outerjoin(cases, items, on = :id => :items_articles_id)
        
        # Reorder columns: cols first, then extract_cols, then id, type, norm_iri
        cases_cols = names(cases)
        @info cases_cols
        final_cols = vcat(intersect(cols, cases_cols), intersect(extract_cols, cases_cols), ["id", "type", "norm_iri"])
        unique!(final_cols)


        if !isempty(final_cols)
            select!(cases, final_cols...)
        end
    end

    # Move id, type, norm_iri to end
    move_cols_to_end!(cases, ["id", "type", "norm_iri"])
    return cases
end

"""
    distill_properties(df::DataFrame;
                      type::Union{Nothing, String} = nothing,
                      cols::Vector{String} = String[],
                      annos::Bool = false,
                      levelup::Union{Nothing, Int} = nothing)

Get the property tree (including annotations).

# Arguments
- `df`: A RAM DataFrame.
- `type`: The property type to filter by.
- `cols`: The property columns to include.
- `annos`: Whether to distill annotations.
- `levelup`: If set to a number, the tree will be simplified by replacing the path value
             on lower levels with the ancestor path from the given level.

# Returns
- A DataFrame containing the properties tree.
"""
function distill_properties(df::DataFrame;
                            type::Union{Nothing, String} = nothing,
                            cols::Vector{String} = String[],
                            annos::Bool = false,
                            levelup::Union{Nothing, Int} = nothing)
    props = epi_extract_long(df, "properties", type; prefix=false)

    if nrow(props) == 0
        @warn "No property data with type $(type) found"
        return props
    end

    # Add missing columns
    add_missing_columns!(props, ["parent_id", "articles_id"], "")
    props[!, :id] = string.(props[!, :id])    
    
    # Select columns
    keep_cols = unique(vcat(["lemma", "type", "norm_iri", "level", "lft", "rght", "id", "parent_id"], cols))
    keep_cols = [c for c in keep_cols if c in names(props)]
    select!(props, keep_cols...)
    
    # Sort by lft
    sort!(props, :lft)
    
    # Add tree path
    props = tree_add_path(props, :id, :parent_id, :lemma)
    
    # Drop empty columns
    drop_empty_columns!(props)

    # Select final columns
    final_cols = unique(vcat(["tree_path", "id", "parent_id"], cols, ["type", "norm_iri"]))
    final_cols = [c for c in final_cols if c in names(props)]
    select!(props, final_cols...)    
    
    # Rename tree_path to path if it's first
    if names(props)[1] == "tree_path"
        rename!(props, :tree_path => :path)
    end

    if annos
        # Items
        items = distill_items(df, nothing, cols = ["articles_id", "sections_id", "property"])
        
        if nrow(items) > 0
            rename!(items, :id => :items_id)
            select!(items, [:property, :articles_id, :sections_id, :items_id])
            items = filter(row -> any(!ismissing, row), items)
            items = innerjoin(props, items, on = :id => :property)
            drop_empty_columns!(items)
        end

        if nrow(items) > 0
            props = antijoin(props, items, on = :id)
        end

        # Links
        links = distill_links(df, properties_type = type, cols = ["segment"], level = nothing)

        if nrow(links) > 0
            links = innerjoin(props, links, on = :id => :to_id)
        end

        if nrow(links) > 0
            drop_empty_columns!(links)
            props = antijoin(props, links, on = :id)
        end

        props = vcat(props, links, items)
    end

    if levelup !== nothing
        add_missing_columns!(props, ["parent_id", "path"], "")
        props = tree_add_ancestor(props, level = levelup, :id, :parent_id, :path)
    end

    return props
end

"""
    distill_items(df::DataFrame;
                 type::Union{Nothing, String} = nothing,
                 cols::Vector{String} = String[],
                 property_cols::Vector{String} = String[],
                 article_cols::Vector{String} = String[])

Get articles (including selected item values).

# Arguments
- `df`: A RAM DataFrame.
- `type`: Item types to filter.
- `cols`: Columns returned from the items.
- `property_cols`: Property columns joined to the items.
- `article_cols`: Article columns joined to the items. Not implemented yet.

# Returns
- A DataFrame with items.
"""
function distill_items(df::DataFrame;
                      type::Union{Nothing, String} = nothing,
                      cols::Vector{String} = String[],
                      property_cols::Vector{String} = String[],
                      article_cols::Vector{String} = String[])
    items = epi_extract_long(df, "items", type; prefix=false)
    items[!, :id] = string.(items[!, :id])

    extract_cols = cols
    if !isempty(property_cols)
        extract_cols = vcat(extract_cols, ["properties." * c for c in property_cols])
    end

    if !isempty(property_cols)
        props = epi_extract_long(df, "properties")
        if nrow(props) > 0
            items[!, :property] = string.(items[!, :property])
            # props has columns prefixed with "properties.", so the id column is "properties.id"
            if Symbol("properties.id") in names(props)
                props[!, Symbol("properties.id")] = string.(props[!, Symbol("properties.id")])
                items = leftjoin(items, props, on = :property => Symbol("properties.id"))
            end
        end
    end

    # Add norm_iri if missing
    add_missing_columns!(items, ["norm_iri"], "")
    
    # Select columns
    # Convert names(items) to Symbols for comparison
    items_cols = [Symbol(c) for c in names(items)]
    final_cols = vcat([Symbol(c) for c in extract_cols], [:id, :type, :norm_iri])
    final_cols = [c for c in final_cols if c in items_cols]
    if !isempty(final_cols)
        select!(items, final_cols...)
    end

    # Replace HTML entities in extract columns
    for col in extract_cols
        if Symbol(col) in names(items)
            items[!, Symbol(col)] = replace.(string.(items[!, Symbol(col)]), "&amp;" => "&")
            items[!, Symbol(col)] = replace.(string.(items[!, Symbol(col)]), "&x2f;" => "&")
        end
    end

    return items
end

"""
    distill_links(df::DataFrame;
                 items_type::Union{Nothing, String} = nothing,
                 properties_type::Union{Nothing, String} = nothing,
                 cols::Vector{String} = ["path", "segment"],
                 article_cols::Vector{String} = String[],
                 level::Union{Nothing, Int} = 0)

Get annotations for the articles.

# Arguments
- `df`: A RAM DataFrame.
- `items_type`: The type of items with annotations.
- `properties_type`: Keep only links that target the given property type.
- `cols`: A list of property columns to join.
- `article_cols`: A list of article columns to join.
- `level`: The aggregation level, beginning with 0. Set to `nothing` to get the lowest level.

# Returns
- A DataFrame containing annotations.
"""
function distill_links(df::DataFrame;
                      items_type::Union{Nothing, String} = nothing,
                      properties_type::Union{Nothing, String} = nothing,
                      cols::Vector{String} = ["path", "segment"],
                      article_cols::Vector{String} = String[],
                      level::Union{Nothing, Int} = 0)

    codes = distill_properties(df, properties_type, cols = ["parent_id", "level", "norm_iri"])
    cases = distill_articles(df, cols = article_cols)
    cases[!, :id] = string.(cases[!, :id])

    # Remove type and norm_iri from cases if present
    if :type in names(cases)
        select!(cases, Not([:type, :norm_iri]))
    end
    
    add_missing_columns!(codes, ["parent_id"], "")
    codes[!, :id] = string.(codes[!, :id])

    # Get ancestors
    ancestors = tree_stack_ancestors(codes, :id, :parent_id, :anc_id)
    ancestors = unique(ancestors)

    if level === nothing
        codes_level = codes
        level = maximum(codes[!, :level])
    else
        codes_level = filter(:level => l -> l == level, codes)
    end

    # Extract links
    links = epi_extract_long(df, "links"; prefix=false)
    if "root_tab" in names(links)
        filter!(:root_tab => t -> t == "articles", links)
    end
    if "from_tab" in names(links)
        filter!(:from_tab => t -> t == "items", links)
    end
    if "to_tab" in names(links)
        filter!(:to_tab => t -> t == "properties", links)
    end

    if nrow(links) == 0
        return DataFrame()
    end

    # Process codings
    codings = links
    for col in [:root_id, :from_id, :from_tagid, :to_id]
        if col in names(codings)
            codings[!, col] = string.(codings[!, col])
        end
    end
    codings = unique(codings, [:root_id, :from_id, :from_tagid, :to_id])
    
    # Join with ancestors
    codings = leftjoin(codings, ancestors, on = :to_id => :id, makeunique=true)

    # Join with codes_level
    codings = innerjoin(codings, codes_level, on = :anc_id => :id)
    codings = unique(codings, [:root_id, :from_id, :from_tagid, :to_id, :path])
    
    # Join with cases
    codings = leftjoin(codings, cases, on = :root_id => :id)

    # Split path into levels
    if :path in names(codings)
        # Split path by " / " delimiter
        max_levels = level + 1
        level_cols = [Symbol("level_$i") for i in 0:level]
        
        split_func(x) = begin
            if ismissing(x) || x == ""
                return fill("", length(level_cols))
            end
            parts = split(x, " / ")
            result = vcat(parts, fill("", max(0, length(level_cols) - length(parts))))
            return result[1:length(level_cols)]
        end
        
        codings = transform!(codings, :path => ByRow(split_func) => level_cols)
        
        # Replace HTML entities
        for lc in level_cols
            if lc in names(codings)
                codings[!, lc] = replace.(string.(codings[!, lc]), "&#47;" => "/")
                codings[!, lc] = replace.(string.(codings[!, lc]), "&x2f;" => "&")
            end
        end
    end

    # Segments in items
    segments = epi_extract_long(df, "items", items_type; prefix=false)
    if nrow(segments) > 0
        rename!(segments, :id => :items_id)
        add_missing_columns!(segments, ["items_id", "sections_id", "articles_id", "content", "norm_iri"], "")
        select!(segments, [:items_id, :sections_id, :articles_id, :content, :norm_iri])
        
        for col in names(segments)
            segments[!, col] = string.(segments[!, col])
        end
        
        segments = innerjoin(segments, codings, on = :items_id => :from_id, makeunique=true)
        segments = transform!(segments, :norm_iri => ByRow(x -> x) => :item_iri)
        select!(segments, [:items_id, :sections_id, :articles_id, :from_tagid, :content, :item_iri])
        
        # Extract segments
        segments = transform!(segments, [:content, :from_tagid] => ByRow(extract_segment) => :segment)
    end

    # Join segments back to codings
    if nrow(segments) > 0
        codings = leftjoin(codings, segments, on = [:from_id, :from_tagid])
    end
    
    rename!(codings, :from_id => :items_id)

    # Select final columns
    final_cols = unique(vcat(
        [Symbol(c) for c in article_cols if c in names(codings)],
        [:articles_id, :sections_id, :items_id, :from_tagid],
        [Symbol(c) for c in cols if c in names(codings)]
    ))
    select!(codings, final_cols...)
    
    # Add to_id if missing
    add_missing_columns!(codings, ["to_id"], missing)
    
    return codings
end

"""
    extract_segment(xml::AbstractString, tagid::AbstractString)::String

Function to extract segments based on ID attribute.

# Arguments
- `xml`: Character value containing XML text.
- `tagid`: Character value containing the tag ID.

# Returns
- A character value containing only the text of elements with the tag ID.
"""
function extract_segment(xml::AbstractString, tagid::AbstractString)::String
    try
        # Simple regex-based extraction for XML text nodes
        # Pattern: find element with id attribute matching tagid, then extract text content
        # Use raw strings to avoid escape sequence issues
        pattern1 = Regex("<([^>]+[\\s]+[^>]*)id=\"" * tagid * "\"([^>]*)>([^<]*)</\\1>")
        m = match(pattern1, xml)
        if m !== nothing
            return strip(m.captures[3])
        end
        
        # Try with single quotes
        pattern2 = Regex("<([^>]+[\\s]+[^>]*)id='" * tagid * "'([^>]*)>([^<]*)</\\1>")
        m = match(pattern2, xml)
        if m !== nothing
            return strip(m.captures[3])
        end
        
        # Try to extract text between tags that have id=tagid anywhere in their attributes
        pattern3 = Regex("id=\"" * tagid * "\"[^>]*>([^<]*)<")
        m = match(pattern3, xml)
        if m !== nothing
            return strip(m.captures[1])
        end
        
        return ""
    catch e
        return ""
    end
end

"""
    extract_untagged(xml::AbstractString)::String

Function to extract non-tagged text.

# Arguments
- `xml`: The XML as character value.

# Returns
- A character value where all text contained in tags was stripped.
"""
function extract_untagged(xml::AbstractString)::String
    try
        # Replace & with HTML entity to avoid issues
        xml = replace(xml, "&" => "&#038;")
        
        # Extract text that is not inside any tags
        # Pattern: text between > and < that is not part of a closing tag
        pattern = Regex(">([^<]*)<")
        matches = eachmatch(pattern, xml)
        texts = [strip(m.captures[1]) for m in matches if m.captures[1] != ""]
        
        return join(filter(!isempty, texts), " ")
    catch e
        return ""
    end
end

"""
    tree_add_path(data::DataFrame, col_id::Symbol, col_parent_id::Symbol, col_lemma::Symbol;
                 delim::String = "/")::DataFrame

Add a column holding the path of each node.

The path is created by concatenating all col_lemma values up to the root node.
Lemmata are concatenated using a slash - existing slashes are replaced by the entity &#47;.

# Arguments
- `data`: DataFrame containing hierarchical data.
- `col_id`: The ID column of the node.
- `col_parent_id`: The ID column of the parent node.
- `col_lemma`: The column holding the node name that will be used for the path.
- `delim`: Character that glues together the path elements. Set to `nothing` to create a vector instead.

# Returns
- A DataFrame with the additional column tree_path.
"""
function tree_add_path(data::DataFrame, col_id::Symbol, col_parent_id::Symbol, col_lemma::Symbol;
                     delim::String = "/")::DataFrame
    # Escape slashes (or other characters used as delimiter) in lemmata
    # For "/", the HTML entity is "&x2f;"    
    delim_entity = delim == "/" ? "&x2f;" : "&amp;"
    transform!(data, col_lemma => ByRow(x -> replace(string(x), delim => delim_entity)) => col_lemma)

    # Initialize path, use lemma for root nodes
    lemma_maybe(parent_id, lemma) = ismissing(parent_id) ? string(lemma) : ""
    transform!(data, [col_parent_id, col_lemma] => ByRow(lemma_maybe) => :tree_path)

    for row in eachrow(data)
        parent_id = row[col_parent_id]
        path_elements = String[]
        n = 0
        nmax = 63 # max nesting level
        while !ismissing(parent_id)
            parent_index = findfirst(isequal(parent_id), data[:, col_id])
            if !isnothing(parent_index)
                push!(path_elements, data[parent_index, col_lemma])
            end
            parent_id = data[parent_index, col_parent_id]
            n += 1
            if n > nmax
                break # avoid infinite loop
            end
        end
        push!(path_elements, row[col_lemma])
        row[:tree_path] = join(path_elements, " " * delim * " ")
    end
    
    return data
end

"""
    tree_stack_ancestors(data::DataFrame, col_id::Symbol, col_parent::Symbol, col_stack::Symbol)::DataFrame

For each node, add each ancestor's id.

In the result, nodes will be duplicated for all their ancestors.
As an example: a node on level 2 will be present two times,
1. the node containing the parent_id in the col_stack column
2. the node containing the parents parent_id in the col_stack column

# Arguments
- `data`: All nodes.
- `col_id`: The column holding IDs of the nodes.
- `col_parent`: The column holding IDs of the parent nodes.
- `col_stack`: The column that will hold the ancestors IDs.

# Returns
- A DataFrame where each node is duplicated with ancestor IDs in the stack column.
"""
function tree_stack_ancestors(data::DataFrame, col_id::Symbol, col_parent::Symbol, col_stack::Symbol)::DataFrame
    # Prepare temporary columns (for easier joins)
    temp_id = Symbol("_tree_id_")
    temp_parent = Symbol("_tree_parent_")
    temp_main = Symbol("_tree_main_")
    
    data = transform!(data, col_id => ByRow(x -> x) => temp_id)
    data = transform!(data, col_parent => ByRow(x -> x) => temp_parent)

    # Put items themselves on the stack
    data_stacked = transform!(data, temp_id => ByRow(x -> x) => temp_main)

    # Init parents (temp_main is the parent id)
    data_parents = filter(temp_parent => p -> !ismissing(p) && p != "", data)
    data_parents = transform!(data_parents, temp_parent => ByRow(x -> x) => temp_main)

    while nrow(data_parents) > 0
        data_stacked = vcat(data_stacked, data_parents)

        # Find parents
        data_parents = innerjoin(data_parents, 
                                select(data, [temp_id, temp_main] => temp_parent),
                                on = temp_main => temp_id, makeunique=true)
        
        if Symbol("_tree_main_y") in names(data_parents)
            filter!(:_tree_main_y => m -> !ismissing(m) && m != "", data_parents)
            data_parents = transform!(data_parents, :_tree_main_y => ByRow(x -> x) => temp_main)
            select!(data_parents, Not([:_tree_main_y]))
        end
    end

    # Remove temporary columns and return data
    select!(data_stacked, Not([temp_id, temp_parent]))
    data_stacked = transform!(data_stacked, temp_main => ByRow(x -> x) => col_stack)
    select!(data_stacked, Not([temp_main]))
    
    return data_stacked
end

"""
    tree_add_ancestor(data::DataFrame; level::Int = 0,
                     col_id::Symbol, col_parent_id::Symbol, col_path::Symbol)::DataFrame

Add ancestor id and path from a specific level to all children.

# Arguments
- `data`: A DataFrame with properties.
- `level`: The target level.
- `col_id`: The column holding property ids.
- `col_parent_id`: The column holding property parent ids.
- `col_path`: The column holding a value (mostly a path or lemma) that will be added in addition to the id.

# Returns
- A DataFrame with the two columns ancestor_id and ancestor_path added.
"""
function tree_add_ancestor(data::DataFrame; level::Int = 0,
                         col_id::Symbol, col_parent_id::Symbol, col_path::Symbol)::DataFrame
    target = unique(data, [col_id, col_parent_id, col_path])
    target = tree_add_level(target, col_id, col_parent_id)
    target = filter(:tree_level => l -> l == level, target)
    rename!(target, col_id => :ancestor_id, col_path => :ancestor_path)
    select!(target, [:ancestor_id, :ancestor_path])

    data = unique(data)
    data = tree_stack_ancestors(data, col_id, col_parent_id, :ancestor_id)
    data = innerjoin(data, target, on = :ancestor_id)
    
    return data
end

"""
    tree_add_level(data::DataFrame, col_id::Symbol, col_parent::Symbol, col_sort::Union{Nothing, Symbol} = nothing)::DataFrame

Add level, thread and order to hierarchical data.

# Arguments
- `data`: The DataFrame containing hierarchical data.
- `col_id`: The ID column of the node.
- `col_parent`: The ID column of the parent node.
- `col_sort`: Column for sorting the nodes inside each parent. Leave empty to use the ID column.

# Returns
- A DataFrame with the additional columns tree_thread, tree_order and tree_level.
"""
function tree_add_level(data::DataFrame, col_id::Symbol, col_parent::Symbol, 
                      col_sort::Union{Nothing, Symbol} = nothing)::DataFrame
    if col_sort === nothing
        col_sort = col_id
    end

    # Prepare temporary column names
    temp_id = Symbol("_tree_id_")
    temp_parent = Symbol("_tree_parent_")

    # Prepare columns
    data = transform!(data, col_id => ByRow(x -> x) => temp_id)
    data = transform!(data, col_parent => ByRow(x -> x) => temp_parent)

    # Prepare roots (nodes with no parent or empty parent)
    roots = antijoin(data, data, on = temp_parent => temp_id)
    roots = transform!(roots, temp_id => ByRow(x -> x) => :tree_thread)
    roots = transform!(roots, ByRow(_ -> 0) => :tree_level)
    roots = transform!(roots, ByRow(_ -> 0) => :tree_order)

    # First level
    current_level = 1
    children = innerjoin(data, select(roots, [temp_id, :tree_thread]), on = temp_parent => temp_id)
    children = transform!(children, ByRow(_ -> current_level) => :tree_level)
    
    children = groupby(children, temp_parent)
    children = combine(children, :tree_level => length => :tree_order)
    # Reset groupby
    ungroup!(children)
    
    while true
        current_level += 1

        # Find next level children
        children_next = antijoin(data, children, on = temp_id)
        children_next = innerjoin(children_next, 
                                  select(children, [temp_id, :tree_thread]), 
                                  on = temp_parent => temp_id)
        children_next = transform!(children_next, ByRow(_ -> current_level) => :tree_level)
        
        children_next = groupby(children_next, temp_parent)
        children_next = combine(children_next, :tree_level => length => :tree_order)
        ungroup!(children_next)

        if nrow(children_next) == 0
            break
        end

        children = vcat(children, children_next)
    end

    result = vcat(roots, children)
    sort!(result, [:tree_thread, :tree_order])
    select!(result, Not([temp_id, temp_parent]))
    
    return result
end
