#
# Functions for Epigraf data handling
#

"""
    epi_create_iri(table, type, fragment; split = false)

Create a clean IRI (Internationalized Resource Identifier)

# Arguments
- `table`: The table name
- `type`: If nothing, the type will be omitted.
- `fragment`: The IRI fragment that will be cleaned
- `split`: If true and the fragment already contains a type, the fragment's type is used

# Returns
- A string with the IRI path, or empty string if any argument is empty
"""
function epi_create_iri(table, type, fragment; split = false)
    # Check for empty arguments
    if isempty(table) || (type !== nothing && isempty(type)) || isempty(fragment)
        return ""
    end

    # Clean the fragment
    fragment = epi_clean_irifragment(fragment)

    # Build the IRI
    table_str = string(table) * "/"
    type_str = type === nothing ? "" : string(type) * "/"
    
    return table_str * type_str * fragment
end

"""
    epi_create_iri(table, type, fragment)

Create a clean IRI with positional arguments (simplified version for compatibility)
"""
function epi_create_iri(table::AbstractString, type::AbstractString, fragment::AbstractString)
    # This version matches the signature used in craft.jl
    # It doesn't handle split parameter and assumes non-empty arguments
    table_str = string(table) * "/"
    type_str = string(type) * "/"
    fragment_str = epi_clean_irifragment(fragment)
    return table_str * type_str * fragment_str
end

"""
    epi_clean_irifragment(fragment)

Create a clean IRI fragment.
Replaces all non alphanumeric characters by hyphens and converts to lowercase.

# Arguments
- `fragment`: The dirty IRI fragment that will be cleaned

# Returns
- A clean IRI fragment
"""
function epi_clean_irifragment(fragment)
    if fragment isa AbstractString
        # Define character replacements for umlauts
        replacements = Dict(
            "ä" => "ae",
            "ö" => "oe", 
            "ü" => "ue",
            "ß" => "ss",
            "å" => "aa",
            "æ" => "ae",
            "ø" => "oe",
            "Ä" => "ae",
            "Ö" => "oe",
            "Ü" => "ue",
            "Å" => "aa",
            "Æ" => "ae",
            "Ø" => "oe"
        )
        
        # Apply replacements
        result = lowercase(string(fragment))
        for (old, new) in replacements
            result = replace(result, old => new)
        end
        
        # Replace non-alphanumeric characters (except underscore, tilde, hyphen) with hyphens
        result = replace(result, r"[^a-z0-9_~-]" => "-")
        
        # Replace multiple consecutive hyphens with single hyphen
        result = replace(result, r"-+" => "-")
        
        # Remove leading/trailing hyphens
        result = replace(result, r"^-" => "")
        result = replace(result, r"-$" => "")
        
        return result
    end
    return fragment
end

"""
    epi_is_iripath(iripath; table = nothing, type = nothing)

Check whether the provided value contains a valid IRI path

# Arguments
- `iripath`: The value that will be checked
- `table`: Check whether the path contains the table. Leave nothing to allow all tables.
- `type`: Check whether the path contains the type. Leave nothing to allow all types.

# Returns
- `true` if valid, `false` otherwise
"""
function epi_is_iripath(iripath; table = nothing, type = nothing)
    if iripath isa AbstractString && !isempty(iripath)
        # Set default regex patterns
        table_pattern = table === nothing ? "(projects|articles|sections|items|properties|links|footnotes|types|users)" : string(table)
        type_pattern = type === nothing ? "[a-z0-9_-]+" : string(type)
        fragment_pattern = "[a-z0-9_~-]+"
        
        # Build the regex
        pattern = Regex("^" * table_pattern * "/" * type_pattern * "/" * fragment_pattern * "\$")
        
        return occursin(pattern, iripath)
    end
    return false
end

"""
    epi_is_id(id; table = nothing)

Check whether the provided value contains valid IDs prefixed with table names.
Example: articles-123

# Arguments
- `id`: The value that will be checked
- `table`: Check whether the path contains the table. Leave nothing to allow all tables.

# Returns
- `true` if valid, `false` otherwise
"""
function epi_is_id(id; table = nothing)
    if id isa AbstractString && !isempty(id)
        table_pattern = table === nothing ? "(projects|articles|sections|items|properties|links|footnotes|types|users)" : string(table)
        fragment_pattern = "[0-9]+"
        
        pattern = Regex("^" * table_pattern * "-" * fragment_pattern * "\$")
        
        return occursin(pattern, id)
    end
    return false
end

"""
    epi_is_id(id, table)

Check whether the provided value contains valid IDs prefixed with table names.
Positional arguments version for compatibility.
"""
function epi_is_id(id, table = nothing)
    return epi_is_id(id; table = table)
end

"""
    epi_is_prefixid(id; table = nothing, prefix = nothing)

Check whether the provided value contains valid IDs prefixed with table names
and temporary prefixes. Example: articles-tmp123

# Arguments
- `id`: The value that will be checked
- `table`: Check whether the path contains the table. Leave nothing to allow all tables.
- `prefix`: Check whether the ID contains the prefix, e.g. "tmp". Leave nothing to allow all prefixes.

# Returns
- `true` if valid, `false` otherwise
"""
function epi_is_prefixid(id; table = nothing, prefix = nothing)
    if id isa AbstractString && !isempty(id)
        table_pattern = table === nothing ? "(projects|articles|sections|items|properties|links|footnotes|types|users)" : string(table)
        prefix_pattern = prefix === nothing ? "[a-z]+" : string(prefix)
        fragment_pattern = "[0-9]+"
        
        pattern = Regex("^" * table_pattern * "-" * prefix_pattern * fragment_pattern * "\$")
        
        return occursin(pattern, id)
    end
    return false
end

"""
    epi_is_irifragment(value)

Check whether the provided value contains only valid IRI fragment characters.

# Arguments
- `value`: The value that will be checked.

# Returns
- `true` if valid, `false` otherwise
"""
function epi_is_irifragment(value)
    if value isa AbstractString
        return occursin(r"^[a-z0-9_~-]+$", value)
    elseif value isa Vector
        return [occursin(r"^[a-z0-9_~-]+$", v) for v in value]
    end
    return false
end

"""
    epi_iri_parent(id; prefix = "~")

Get the IRI fragment of an IRI path

# Arguments
- `id`: An IRI path
- `prefix`: A prefix added to the IRI fragment, if the ID is not nothing.

# Returns
- The IRI fragment with prefix
"""
function epi_iri_parent(id; prefix = "~")
    if id === nothing || ismissing(id)
        return ""
    end
    
    parts = split(string(id), "/")
    if isempty(parts)
        return ""
    end
    
    last_part = last(parts)
    return string(last_part) * prefix
end

"""
    epi_iri_parent(id)

Get the IRI parent path from an IRI.
This version returns the parent path (all parts except last).
"""
function epi_iri_parent(id::AbstractString)
    parts = split(id, "/")
    if length(parts) > 1
        return join(parts[1:end-1], "/")
    end
    return id
end

"""
    epi_extract_long(df, table, type = nothing; prefix = true)

Get RAM rows by table name

# Arguments
- `df`: A RAM DataFrame
- `table`: The table name
- `type`: Filter by type
- `prefix`: Whether to prefix the columns with the table name

# Returns
- A DataFrame with the filtered rows and columns prefixed with the table name
"""
function epi_extract_long(df, table, type = nothing; prefix = true)
    # Filter by table
    df = filter(:table => t -> t == table, df)
    
    # Filter by type if provided
    if type !== nothing
        df = filter(:type => t -> t == type, df)
    end
    
    # Drop empty columns
    df = drop_empty_columns(df)
    
    # Get distinct rows
    df = unique(df)
    
    # Optionally remove ID columns
    # df = select(df, Not(["table", "type", "norm_iri", "row"]))
    
    # Prefix columns if requested
    if prefix
        rename!(df, [Symbol(string(col)) => Symbol(string(table) * "." * col) for col in names(df)])
    end
    
    return df
end

"""
    epi_extract_wide(data, cols_prefix; cols_keep = String[])

Select nested data from prefixed columns

# Arguments
- `data`: A DataFrame
- `cols_prefix`: All columns with the prefix will be selected, the prefix will be removed from the column name.
- `cols_keep`: Convert the provided column names to underscored columns

# Returns
- A DataFrame containing all columns with the prefix without the prefix
"""
function epi_extract_wide(data, cols_prefix; cols_keep = String[])
    prefix_str = string(cols_prefix)
    
    # Build regex for columns to keep
    if !isempty(cols_keep)
        regex_keep_parts = vcat([prefix_str * "." * k for k in cols_keep], [k * "_id" for k in cols_keep])
        regex_keep = "^" * join(regex_keep_parts, "|") * "\$"
    else
        regex_keep = "^\$"
    end
    
    # Select columns starting with prefix followed by dot, or matching cols_keep
    selected_cols = Symbol[]
    for col in names(data)
        col_str = string(col)
        if startswith(col_str, prefix_str * ".") || occursin(Regex(regex_keep), col_str)
            push!(selected_cols, col)
        end
    end
    
    df = select(data, selected_cols...)
    
    # Rename columns: remove prefix and replace dots with underscores
    rename!(df, [Symbol(c) => Symbol(replace(string(c), Regex(prefix_str * "\\.") => "")) for c in names(df)])
    rename!(df, [Symbol(c) => Symbol(replace(string(c), "." => "_")) for c in names(df)])
    
    # Get distinct rows
    df = unique(df)
    
    # Remove columns where all values are missing
    df = select(df, [col for col in names(df) if !all(ismissing, df[!, col])])
    
    # Filter rows where all values are missing
    df = filter(df) do row
        any(!ismissing, row)
    end
    
    # Remove data that only contains ID columns
    non_id_cols = setdiff(names(df), [Symbol("id"), [Symbol(k * "_id") for k in cols_keep]...])
    if isempty(non_id_cols)
        return DataFrame()
    end
    
    return df
end

"""
    epi_wide_to_long(data)

Convert wide to long format

Extracts nested data from columns prefixed with "properties", "items", "sections",
"articles" and "projects" followed by a dot (e.g. "properties.id", "properties.lemma")
and stacks them to the DataFrame.

# Arguments
- `data`: A DataFrame with the column `id` containing a valid IRI path.

# Returns
- A DataFrame with all input rows and the nested records stacked.
"""
function epi_wide_to_long(data)
    if nrow(data) == 0
        return data
    end
    
    rows = DataFrame()
    
    # Extract nested rows
    for prefix in ["properties", "projects", "articles", "sections", "items"]
        extracted = epi_extract_wide(data, prefix)
        if nrow(extracted) > 0
            rows = vcat(rows, extracted)
        end
    end
    
    # For articles, also extract with projects prefix
    articles_extracted = epi_extract_wide(data, "articles", cols_keep = ["projects"])
    if nrow(articles_extracted) > 0
        rows = vcat(rows, articles_extracted)
    end
    
    # For sections, also extract with articles prefix
    sections_extracted = epi_extract_wide(data, "sections", cols_keep = ["articles"])
    if nrow(sections_extracted) > 0
        rows = vcat(rows, sections_extracted)
    end
    
    # For items, also extract with articles and sections prefixes
    items_extracted = epi_extract_wide(data, "items", cols_keep = ["articles", "sections"])
    if nrow(items_extracted) > 0
        rows = vcat(rows, items_extracted)
    end
    
    # All other rows (non-prefixed columns and ID columns)
    id_cols = [Symbol("id"), Symbol("projects_id"), Symbol("articles_id"), 
               Symbol("sections_id"), Symbol("items_id"), Symbol("properties_id")]
    
    other_cols = Symbol[]
    for col in names(data)
        col_str = string(col)
        # Keep columns that are plain names or ID columns
        if !occursin(r"\.", col_str) || col in id_cols
            push!(other_cols, col)
        end
    end
    
    extracted = select(data, other_cols...)
    # Rename columns with dots to underscores
    rename!(extracted, [Symbol(c) => Symbol(replace(string(c), "." => "_")) for c in names(extracted)])
    
    if nrow(rows) == 0
        rows = extracted
    elseif nrow(extracted) > 0 && ncol(extracted) > 0
        rows = vcat(rows, extracted)
    end
    
    # Validate IDs
    if nrow(rows) > 0
        has_valid_id = false
        for id in rows.id
            if epi_is_iripath(id) || epi_is_id(id)
                has_valid_id = true
                break
            end
        end
        if !has_valid_id
            throw(ErrorException("Data contains invalid IDs"))
        end
    end
    
    # Create table columns
    if nrow(rows) > 0 && ncol(rows) > 0
        rows = filter(row -> any(!ismissing, row), rows)
        
        # Extract table name from ID
        table_col = String[]
        for id in rows.id
            if id isa AbstractString
                m = match(r"^([^/]+)", id)
                push!(table_col, m === nothing ? "" : m.captures[1])
            else
                push!(table_col, "")
            end
        end
        
        rows = hcat(DataFrame(table = table_col), rows)
        
        # Move table and id to front
        if :table in names(rows) && :id in names(rows)
            other_cols = setdiff(names(rows), [:table, :id])
            rows = select(rows, [:table, :id, other_cols...])
        end
    end
    
    return rows
end
