#
# Functions for mapping data to the Relational Article Model (RAM)
#

"""
    df_to_ram(df;
              project_cols = Dict(), project_fill = Dict(),
              article_cols = Dict(), article_fill = Dict(),
              section_cols = Dict(), section_fill = Dict(),
              property_cols = Dict(), property_fill = Dict(),
              item_cols = Dict(), item_fill = Dict(),
              compile = false)

Map a DataFrame to the Relational Article Model (RAM)

Calls craft methods for projects, articles, sections, items and properties.
Alternatively, you can use the craft methods directly.

# Arguments
- `df`: A DataFrame with the source data
- `project_cols`: A named dictionary. Keys are RAM columns, values are source columns.
- `project_fill`: A named dictionary with fixed values for the rows.
- `article_cols`: A named dictionary. Keys are RAM columns, values are source columns.
- `article_fill`: A named dictionary with fixed values for the rows.
- `section_cols`: A named dictionary. Keys are RAM columns, values are source columns.
- `section_fill`: A named dictionary with fixed values for the rows.
- `property_cols`: A named dictionary. Keys are RAM columns, values are source columns.
- `property_fill`: A named dictionary with fixed values for the rows.
- `item_cols`: A named dictionary. Keys are RAM columns, values are source columns.
- `item_fill`: A named dictionary with fixed values for the rows.
- `compile`: Whether to return the compiled RAM rows or a RAM enhanced DataFrame.

# Returns
- When compile is true: a RAM DataFrame, ready for patching into the Epigraf database.
- When compile is false: a RAM-enhanced DataFrame.
"""
function df_to_ram(df;
                  project_cols = Dict(), project_fill = Dict(),
                  article_cols = Dict(), article_fill = Dict(),
                  section_cols = Dict(), section_fill = Dict(),
                  property_cols = Dict(), property_fill = Dict(),
                  item_cols = Dict(), item_fill = Dict(),
                  compile = false)

    if length(vcat(collect(keys(property_cols)), collect(keys(property_fill)))) > 0
        df = craft_properties(df, property_cols, property_fill)
    end

    if length(vcat(collect(keys(project_cols)), collect(keys(project_fill)))) > 0
        df = craft_projects(df, project_cols, project_fill)
    end

    if length(vcat(collect(keys(article_cols)), collect(keys(article_fill)))) > 0
        df = craft_articles(df, article_cols, article_fill)
    end

    if length(vcat(collect(keys(section_cols)), collect(keys(section_fill)))) > 0
        df = craft_sections(df, section_cols, section_fill)
    end

    if length(vcat(collect(keys(item_cols)), collect(keys(item_fill)))) > 0
        df = craft_items(df, item_cols, item_fill)
    end

    if compile
        return ram_compile(df)
    end

    return df
end

"""
    craft_projects(df, cols = Dict(), fill = Dict())

Create RAM rows for project data

# Arguments
- `df`: The source DataFrame
- `cols`: The mapping of source columns to RAM columns
- `fill`: Fixed values for the RAM

# Returns
- A RAM-enhanced DataFrame
"""
function craft_projects(df, cols = Dict(), fill = Dict())
    cols = merge_vectors(cols, Dict("type" => "project.type", "fragment" => "project.fragment"))

    rows = copy(df)
    rows = default_values(rows, cols["fragment"], "default")
    rows = default_values(rows, cols["type"], "default")

    # Select only the columns in cols
    col_names = collect(keys(cols))
    available_cols = intersect(col_names, names(rows))
    rows = rows[!, available_cols]
    rename!(rows, [cols[c] => c for c in available_cols])

    if nrow(rows) > 0
        for (name, value) in fill
            rows[!, name] .= value
        end
    end

    rows[!, :id] = epi_create_iri.("projects", rows.type, rows.fragment)
    select!(rows, Not([:type, :fragment]))
    cols_list = names(rows)

    df[!, :project] = rows.id
    rows[!, :project] = rows.id

    rows = unique(rows)
    if nrow(rows) > 0
        rows[!, :_fields] = join(vcat(cols_list, ["type", "norm_iri"]), ",")
    end

    df = ram_add(df, rows)
    return df
end

"""
    craft_articles(df, cols = Dict(), fill = Dict())

Create RAM rows for article data

# Arguments
- `df`: The source DataFrame
- `cols`: The mapping of source columns to RAM columns
- `fill`: Fixed values

# Returns
- A RAM-enhanced DataFrame
"""
function craft_articles(df, cols = Dict(), fill = Dict())
    if !(":project" in names(df)) && !("project" in names(df))
        throw(ErrorException("Please, craft a project first"))
    end

    project_col = (":project" in names(df)) ? :project : Symbol("project")

    cols = merge_vectors(cols, Dict("fragment" => "article.fragment", "type" => "article.type", "projects_id" => ".project"))
    rows = copy(df)
    rows = default_values(rows, cols["fragment"], "default")
    rows = default_values(rows, cols["type"], "default")

    col_names = collect(keys(cols))
    available_cols = intersect(col_names, names(rows))
    rows = rows[!, available_cols]
    rename!(rows, [cols[c] => c for c in available_cols])

    for (name, value) in fill
        rows[!, name] .= value
    end

    rows[!, :id] = epi_create_iri.("articles", rows.type, rows.fragment)
    select!(rows, Not([:type, :fragment]))
    cols_list = names(rows)

    df[!, :article] = rows.id
    rows[!, :article] = rows.id
    rows[!, :project] = df[!, project_col]

    rows = unique(rows)
    if nrow(rows) > 0
        rows[!, :_fields] = join(vcat(cols_list, ["type", "norm_iri"]), ",")
    end

    df = ram_add(df, rows)
    return df
end

"""
    craft_sections(df, cols = Dict(), fill = Dict())

Create RAM rows for section data

# Arguments
- `df`: The source DataFrame
- `cols`: The mapping of source columns to RAM columns
- `fill`: Fixed values

# Returns
- A RAM-enhanced DataFrame
"""
function craft_sections(df, cols = Dict(), fill = Dict())
    if !(":project" in names(df)) && !("project" in names(df))
        throw(ErrorException("Please, craft a project first"))
    end

    if !(":article" in names(df)) && !("article" in names(df))
        throw(ErrorException("Please, craft an article first"))
    end

    project_col = (":project" in names(df)) ? :project : Symbol("project")
    article_col = (":article" in names(df)) ? :article : Symbol("article")

    cols = merge_vectors(cols, Dict("fragment" => "section.fragment", "type" => "section.type", 
                                    "articles_id" => ".article", "projects_id" => ".project"))
    rows = copy(df)
    rows = default_values(rows, cols["fragment"], "default")
    rows = default_values(rows, cols["type"], "default")

    col_names = collect(keys(cols))
    available_cols = intersect(col_names, names(rows))
    rows = rows[!, available_cols]
    rename!(rows, [cols[c] => c for c in available_cols])

    if nrow(rows) > 0
        for (name, value) in fill
            rows[!, name] .= value
        end
    end

    rows[!, :id] = epi_create_iri.("sections", rows.type, string.(epi_iri_parent.(rows.articles_id)) .* rows.fragment)
    select!(rows, Not([:fragment, :type]))
    cols_list = names(rows)

    df[!, :section] = rows.id
    rows[!, :section] = rows.id
    rows[!, :project] = df[!, project_col]
    rows[!, :article] = df[!, article_col]

    rows = unique(rows)
    if nrow(rows) > 0
        rows[!, :_fields] = join(vcat(cols_list, ["type", "norm_iri"]), ",")
    end

    df = ram_add(df, rows)
    return df
end

"""
    craft_items(df, cols = Dict(), fill = Dict())

Create RAM rows for item data

# Arguments
- `df`: The source DataFrame
- `cols`: The mapping of source columns to RAM columns
- `fill`: Fixed values

# Returns
- A RAM-enhanced DataFrame
"""
function craft_items(df, cols = Dict(), fill = Dict())
    if !(":project" in names(df)) && !("project" in names(df))
        throw(ErrorException("Please, map a project first"))
    end

    if !(":article" in names(df)) && !("article" in names(df))
        throw(ErrorException("Please, map an article first"))
    end

    if !(":section" in names(df)) && !("section" in names(df))
        throw(ErrorException("Please, map a section first"))
    end

    project_col = (":project" in names(df)) ? :project : Symbol("project")
    article_col = (":article" in names(df)) ? :article : Symbol("article")
    section_col = (":section" in names(df)) ? :section : Symbol("section")

    cols = merge_vectors(cols, Dict("fragment" => "item.fragment", "type" => "item.type",
                                    "sections_id" => ".section", "articles_id" => ".article",
                                    "projects_id" => ".project"))
    rows = copy(df)
    rows = default_values(rows, cols["fragment"], "default")
    rows = default_values(rows, cols["type"], "default")

    col_names = collect(keys(cols))
    available_cols = intersect(col_names, names(rows))
    rows = rows[!, available_cols]
    rename!(rows, [cols[c] => c for c in available_cols])

    if nrow(rows) > 0
        for (name, value) in fill
            rows[!, name] .= value
        end
    end

    rows[!, :id] = epi_create_iri.("items", rows.type, string.(epi_iri_parent.(rows.sections_id)) .* rows.fragment)
    select!(rows, Not([:type, :fragment]))
    cols_list = names(rows)

    df[!, :item] = rows.id
    rows[!, :item] = rows.id

    rows[!, :project] = df[!, project_col]
    rows[!, :article] = df[!, article_col]
    rows[!, :section] = df[!, section_col]

    rows = unique(rows)
    if nrow(rows) > 0
        rows[!, :_fields] = join(vcat(cols_list, ["type", "norm_iri"]), ",")
    end

    df = ram_add(df, rows)
    return df
end

"""
    craft_properties(df, cols = Dict(), fill = Dict())

Create RAM rows for property data

# Arguments
- `df`: The source DataFrame
- `cols`: The mapping of source columns to RAM columns
- `fill`: Fixed values

# Returns
- A RAM-enhanced DataFrame
"""
function craft_properties(df, cols = Dict(), fill = Dict())
    cols = merge_vectors(cols, Dict("fragment" => "property.id", "type" => "property.type"))
    rows = copy(df)
    rows = default_values(rows, cols["fragment"], "default")
    rows = default_values(rows, cols["type"], "default")

    col_names = collect(keys(cols))
    available_cols = intersect(col_names, names(rows))
    rows = rows[!, available_cols]
    rename!(rows, [cols[c] => c for c in available_cols])

    if nrow(rows) > 0
        for (name, value) in fill
            rows[!, name] .= value
        end
    end

    rows[!, :id] = epi_create_iri.("properties", rows.type, rows.fragment)
    select!(rows, Not([:type, :fragment]))
    cols_list = names(rows)

    df[!, :property] = rows.id
    rows[!, :property] = rows.id

    rows = unique(rows)
    if nrow(rows) > 0
        rows[!, :_fields] = join(vcat(cols_list, ["type", "norm_iri"]), ",")
    end

    df = ram_add(df, rows)
    return df
end

# Helper functions for RAM operations

"""
    ram_add(df, rows)

Add RAM rows to a DataFrame

# Arguments
- `df`: The DataFrame to add rows to
- `rows`: The RAM rows to add

# Returns
- A RAM-enhanced DataFrame
"""
function ram_add(df, rows)
    if nrow(rows) > 0
        if !hasproperty(df, :epi)
            df[!, :epi] = [Dict() for _ in 1:nrow(df)]
        end
        for i in 1:nrow(df)
            if !haskey(df.epi[i], :ram)
                df.epi[i][:ram] = DataFrame[]
            end
            push!(df.epi[i][:ram], rows)
        end
    end
    return df
end

"""
    ram_compile(df)

Compile RAM rows from a RAM-enhanced DataFrame

# Arguments
- `df`: A RAM-enhanced DataFrame

# Returns
- A compiled RAM DataFrame
"""
function ram_compile(df)
    result = DataFrame()
    if hasproperty(df, :epi)
        for i in 1:nrow(df)
            if haskey(df.epi[i], :ram)
                for ram_df in df.epi[i][:ram]
                    result = vcat(result, ram_df)
                end
            end
        end
    end
    return result
end
