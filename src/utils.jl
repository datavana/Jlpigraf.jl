# Remove NA entries from a list
function na_omit_list(object::Vector{Any})::Vector{Any}
    return object[.!all.(isnan.(object))]
end

# Ask user to confirm script execution
function confirm_action()::Bool
    silent = get(ENV, "epi_silent", "FALSE")
    if silent == "TRUE"
        return true
    end

    print("Are you sure you want to proceed? (y/n)  ")
    user_input = readline()
    if user_input != "y"
        error("Canceled")
    end
    return true
end

# Check whether the URL is on a local server
function is_local_server(server::AbstractString)::Bool
    return startswith(server, "https://127.0.0.1") ||
           startswith(server, "http://127.0.0.1") ||
           startswith(server, "https://localhost") ||
           startswith(server, "http://localhost")
end

# Remove HTML entities
function unescape_html(str::AbstractString)::AbstractString
    if isnan(str)
        return str
    else
        # Using Gumbo for HTML parsing
        doc = parsehtml("<x>" * str * "</x>")
        return textContent(doc.root)
    end
end

# Remove empty columns
function drop_empty_columns(df::DataFrame)::DataFrame
    return df[:, findall(col -> any(.!isnan.(col)), eachcol(df))]
end

# Add columns if they are missing from the data frame
function add_missing_columns(df::DataFrame, cols::Vector{String}, default::Any = missing)::DataFrame
    missing_cols = setdiff(cols, names(df))
    for col in missing_cols
        df[!, col] .= default
    end
    return df
end

# Shift selected columns to the front
function move_cols_to_front(df::DataFrame, cols::Vector{String})::DataFrame
    existing_cols = intersect(cols, names(df))
    other_cols = setdiff(names(df), existing_cols)
    return df[:, vcat(existing_cols, other_cols)]
end

# Shift selected columns to the end
function move_cols_to_end(df::DataFrame, cols::Vector{String})::DataFrame
    existing_cols = intersect(cols, names(df))
    other_cols = setdiff(names(df), existing_cols)
    return df[:, vcat(other_cols, existing_cols)]
end

# Parse JSON columns
function parse_json(data::Vector{String})::Vector{Any}
    data[data .== "[]"] .= "{}"
    data[isnan.(data)] .= "{}"
    return JSON.parse.(data)
end

# Merge list elements by their name
function merge_lists(l::Vector{Vector{Pair{String, Any}}})::Dict{String, Any}
    keys = unique(vcat([keys(d) for d in l]...))
    merged = Dict{String, Any}()
    for key in keys
        merged[key] = vcat([get(d, key, []) for d in l]...)
    end
    return merged
end

# Convert a number to letters, e.g., 3 becomes "c"
function num2abc(number::Int, base::Int = 26)::String
    n = ceil(log((1 / (1 - base) - 1 - number) * (1 - base)) / log(base)) - 1
    digits = encode(number - sum(base .^ (0:n-1)), fill(base, n))
    return join(['a' + d for d in digits])
end

# Convert letters to a number, e.g., "c" becomes 3
function abc2num(s::AbstractString, base::Int = 26)::Int
    s = lowercase(s)
    chars = collect(s)
    digits = [Int(c) - Int('a') for c in chars]
    n = length(digits)
    offset = n > 1 ? sum(base .^ (0:n-2)) : 0
    number = sum(digits .* base .^ reverse(0:n-1))
    return number + offset + 1
end

# Converts "b" using the "base"
function decode(b::Vector{Int}, base::Vector{Int})::Int
    if length(base) == 1
        base = fill(base[1], length(b))
    end
    base = vcat(base, 1)
    number = sum(cumprod(reverse(base)[1:length(b)]) .* reverse(b))
    return number
end

# Converts numbers using the radix vector
function encode(number::Int, base::Vector{Int})::Vector{Int}
    n_base = length(base)
    result = zeros(Int, n_base, length(number))
    for i in n_base:-1:1
        result[i, :] = base[i] > 0 ? number .% base[i] : number
        number = base[i] > 0 ? number .÷ base[i] : 0
    end
    return length(number) == 1 ? result[:, 1] : result
end

# Create distinct pseudonyms
function pseudonyms(n::Int)::Vector{String}
    letters_consonant = ["b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "w", "x", "z"]
    letters_vocal = ["a", "e", "i", "o", "u"]

    candidates = String[]
    todo = n
    iterations = 0

    while todo > 0
        if iterations > 100
            error("Could not create sufficient values in 100 iterations.")
        end

        new_candidates = [
            uppercase(rand(letters_consonant)) *
            rand(letters_vocal) *
            rand(letters_consonant) *
            rand(letters_vocal) *
            rand(letters_consonant) *
            rand(letters_vocal)
            for _ in 1:todo
        ]

        candidates = unique(vcat(candidates, new_candidates))
        todo = n - length(candidates)
        iterations += 1
    end

    return candidates
end

# Bind rows of dataframes even if column types differ
function bind_rows_char(dataframes::Vector{DataFrame})::DataFrame
    col_names = unique(vcat([names(df) for df in dataframes]...))
    col_classes = Dict{String, Vector{DataType}}()
    for colname in col_names
        col_classes[colname] = unique([
            colname in names(df) ? eltype(df[!, colname]) : Missing for df in dataframes
        ])
    end

    cols_tocharacter = Dict{String, Bool}()
    for (colname, classes) in col_classes
        cols_tocharacter[colname] = length(filter(!ismissing, classes)) > 1
    end

    if !isempty(cols_tocharacter)
        for df in dataframes
            for colname in names(df)
                if get(cols_tocharacter, colname, false)
                    df[!, colname] = string.(df[!, colname])
                end
            end
        end
    end

    return vcat(dataframes...)
end

# Merge vectors
function merge_vectors(values::Dict{String, Any}, default::Dict{String, Any})::Dict{String, Any}
    merged = copy(default)
    for (key, value) in values
        merged[key] = value
    end
    return merged
end

# Set default values
function default_values(df::DataFrame, colname::String, default::Any)::DataFrame
    if !(colname in names(df))
        df[!, colname] .= default
    end
    return df
end

# Get file extension from URL path component
function get_extension(path::AbstractString)::String
    filename = basename(path)
    if occursin(r"\.", filename)
        ext = match(r"\.([^.]*)$", filename).captures[1]
        if startswith(filename, ".") && !occursin(r"\..+\.", filename)
            return ""
        else
            return ext
        end
    else
        return ""
    end
end

# Join folder and filename
function join_path(filename::AbstractString, filepath::Union{String, Nothing} = nothing)::String
    if isnothing(filepath) || filepath == ""
        return filename
    else
        return joinpath(filepath, filename)
    end
end

"""
    subset_by_col(df::AbstractDataFrame, col_cmp...)

Filter `df` by comparing the values in `col_cmp` with the columns in `df`

# Example
``` julia
julia> df = DataFrame(
    a = ["w", "d", "f", "k", "v", "d"], 
    b = [1, 2, 1, 2, 1, 2], 
    c = [1.2, 7.8, 3.1, 5.0, 4.4, 3.2]
)
    
6×3 DataFrame
 Row │ a       b      c
     │ String  Int64  Float64
─────┼────────────────────────
   1 │ w           1      1.2
   2 │ d           2      7.8
   3 │ f           1      3.1
   4 │ k           2      5.0
   5 │ v           1      4.4
   6 │ d           2      3.2

julia> subset_by_col(df, :a => "d", :b => 2)
2×3 DataFrame
 Row │ a       b      c
     │ String  Int64  Float64
─────┼────────────────────────
   1 │ d           2      7.8
   2 │ d           2      3.2
```   
"""
function subset_by_col(df::AbstractDataFrame, col_cmp...)
    col_cond = []
    for cc in col_cmp
        push!(col_cond, cc[1] => x -> x.==cc[2])
    end
    return subset(df, col_cond...)
end

# For use in a pipe
subset_by_col(col_cmp...) = df -> subset_by_col(df, col_cmp...)
