"""
    na_omit_list(object::Vector{Any})::Vector{Any}

Remove NA entries from a list.

# Arguments
- `object`: A vector from which to remove NA entries.
"""
function na_omit_list(object::Vector{Any})::Vector{Any}
    error("not defined")
end

"""
    confirm_action()::Bool

Ask user to confirm script execution.

# Arguments
- None. Uses `EPI_SILENT` environment variable to determine if prompts should be shown.

# Returns
- `true` if confirmed or silent mode is active, otherwise throws an error.
"""
function confirm_action()::Bool
    silent = get(ENV, "epi_silent", "FALSE")
    if silent == "TRUE"
        return true
    end

    print("Are you sure you want to proceed? (y/n)  ")
    user_input = readline()
    if !in(user_input, ("y", "yes"))
        error("Canceled")
    end
    return true
end

"""
    is_local_server(server::AbstractString)::Bool

Check whether the URL is on a local server.

# Arguments
- `server`: The server URL to check.
"""
function is_local_server(server::AbstractString)::Bool
    return startswith(server, "https://127.") ||
           startswith(server, "http://127.") ||
           startswith(server, "https://localhost") ||
           startswith(server, "http://localhost")
end

"""
    unescape_html(str)

Remove HTML entities from a string.

# Arguments
- `str`: The string containing HTML entities.
"""
function unescape_html(str)
    if ismissing(str)
        return str
    else
        error("unescape_html not defined")
    end
end

"""
    drop_empty_columns!(df::DataFrame)::DataFrame

Remove empty columns from a DataFrame.

# Arguments
- `df`: The DataFrame to process.
"""
function drop_empty_columns!(df)
    select!(df, [col for col in names(df) if any(!ismissing, df[!, col])])
    return df
end

"""
    add_missing_columns!(df::DataFrame, cols::Vector{String}, default::Any = missing)::DataFrame

Add columns if they are missing from the DataFrame.

# Arguments
- `df`: The DataFrame to process.
- `cols`: Vector of column names to ensure exist.
- `default`: Default value for new columns, defaults to `missing`.
"""
function add_missing_columns!(df::DataFrame, cols::Vector{String}, default::Any = missing)::DataFrame
    missing_cols = setdiff(cols, names(df))
    for col in missing_cols
        df[!, col] .= default
    end
    return df
end

"""
    move_cols_to_front!(df::DataFrame, cols::Vector{String})::DataFrame

Shift selected columns to the front of a DataFrame.

# Arguments
- `df`: The DataFrame to process.
- `cols`: Vector of column names to move to the front.
"""
function move_cols_to_front!(df::DataFrame, cols::Vector{String})::DataFrame
    existing_cols = intersect(cols, names(df))
    other_cols = setdiff(names(df), existing_cols)
    select!(df, vcat(existing_cols, other_cols)...)
    return df
end

"""
    move_cols_to_end!(df::DataFrame, cols::Vector{String})::DataFrame

Shift selected columns to the end of a DataFrame.

# Arguments
- `df`: The DataFrame to process.
- `cols`: Vector of column names to move to the end.
"""
function move_cols_to_end!(df::DataFrame, cols::Vector{String})::DataFrame
    existing_cols = intersect(cols, names(df))
    other_cols = setdiff(names(df), existing_cols)
    select!(df, vcat(other_cols, existing_cols)...)
    return df    
end

"""
    parse_json(data::Vector{String})::Vector{Any}

Parse JSON columns from a vector of strings.

# Arguments
- `data`: Vector of JSON strings to parse.
"""
function parse_json(data::Vector{String})::Vector{Any}
    data[data .== "[]"] .= "{}"
    data[ismissing.(data)] .= "{}"
    return JSON.parse.(data)
end

"""
    merge_lists(l)

Merge list elements by their name.

# Arguments
- `l`: Vector of vectors of name-value pairs to merge.
"""
function merge_lists(l)
    error("merge_lists not defined; use merge(d1, d2) for dictionaries")    
end

"""
    num2abc(number::Int, base::Int = 26)::String

Convert a number to letters (e.g., 3 becomes "c").

# Arguments
- `number`: The number to convert.
- `base`: The base for conversion, defaults to 26.
"""
function num2abc(number::Int, base::Int = 26)::String
    string('a' + mod(number - 1, base))
end

"""
    abc2num(s::AbstractString, base::Int = 26)::Int

Convert letters to a number (e.g., "c" becomes 3).

# Arguments
- `s`: The string to convert.
- `base`: The base for conversion, defaults to 26.
"""
function abc2num(s::AbstractString, base::Int = 26)::Int
    Int(s[1] - 'a' + 1)
    # version that accepts multicharacter strings
    # s = lowercase(s)
    # chars = collect(s)
    # digits = [Int(c) - Int('a') for c in chars]
    # n = length(digits)
    # offset = n > 1 ? sum(base .^ (0:n-2)) : 0
    # number = sum(digits .* base .^ reverse(0:n-1))
    # return number + offset + 1
end

"""
    decode(b::Vector{Int}, base::Vector{Int})::Int

Converts a vector "b" using the given base.

# Arguments
- `b`: The vector to decode.
- `base`: The base vector for decoding.
"""
function decode(b::Vector{Int}, base::Vector{Int})::Int
    if length(base) == 1
        base = fill(base[1], length(b))
    end
    base = vcat(base, 1)
    number = sum(cumprod(reverse(base)[1:length(b)]) .* reverse(b))
    return number
end

"""
    encode(number::Int, base::Vector{Int})::Vector{Int}

Converts numbers using the radix vector.

# Arguments
- `number`: The number to encode.
- `base`: The base vector for encoding.
"""
function encode(number::Int, base::Vector{Int})::Vector{Int}
    n_base = length(base)
    result = zeros(Int, n_base, length(number))
    for i in n_base:-1:1
        result[i, :] = base[i] > 0 ? number .% base[i] : number
        number = base[i] > 0 ? number .\ base[i] : 0
    end
    return length(number) == 1 ? result[:, 1] : result
end

"""
    pseudonyms(n::Int)::Vector{String}

Create distinct pseudonyms.

# Arguments
- `n`: The number of pseudonyms to create.
"""
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

"""
    bind_rows_char(dataframes::Vector{DataFrame})::DataFrame

Bind rows of DataFrames even if column types differ.

# Arguments
- `dataframes`: Vector of DataFrames to bind.
"""
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

"""
    merge_vectors(values, default)

Merge values dictionary with default dictionary.
Values from the values dictionary take precedence over defaults.

# Arguments
- `values`: Dictionary with values to merge.
- `default`: Default dictionary to use as base.

# Returns
- Merged dictionary with values taking precedence over defaults.
"""
function merge_vectors(values::Dict, default::Dict)::Dict
    result = copy(default)
    for (k, v) in values
        result[k] = v
    end
    return result
end

"""
    default_values(df::DataFrame, colname::String, default::Any)::DataFrame

Set default values for a column in a DataFrame.

# Arguments
- `df`: The DataFrame to process.
- `colname`: The column name.
- `default`: The default value to set.
"""
function default_values(df::DataFrame, colname::String, default::Any)::DataFrame
    if !(colname in names(df))
        df[!, colname] .= default
    end
    return df
end

"""
    get_extension(path::AbstractString)::String

Get file extension from URL path component.

# Arguments
- `path`: The URL path to extract the extension from.
"""
function get_extension(path::AbstractString)::String
    error("get_extension is not defined, use splitext(path) |> last" )
end


"""
    subset_by_col(df::AbstractDataFrame, col_cmp...)

Filter `df` by comparing the values in `col_cmp` with the columns in `df`.

# Arguments
- `df`: The DataFrame to filter.
- `col_cmp`: Column comparisons in the form `column => value`.

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

"""
    subset_by_col(col_cmp...)

For use in a pipe. Creates a function that filters a DataFrame by column comparisons.

# Arguments
- `col_cmp`: Column comparisons in the form `column => value`.
"""
subset_by_col(col_cmp...) = df -> subset_by_col(df, col_cmp...)
