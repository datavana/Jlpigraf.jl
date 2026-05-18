#
# Functions for validation checks
#

"""
    check_has_column(data, col; msg = nothing)

Check whether a column exists and stop if not

# Arguments
- `data`: A DataFrame
- `col`: A column name (as Symbol or String)
- `msg`: A custom error message if the check fails

# Returns
- `true` if the column exists
"""
function check_has_column(data, col; msg = nothing)
    colname = string(col)

    if isempty(colname)
        msg = !isnothing(msg) ? msg : "Did you miss to say which column to use?"
        throw(ErrorException(msg))
    end

    if !(colname in names(data))
        msg = !isnothing(msg) ? msg : "The column $(colname) does not exist, check your parameters."
        throw(ErrorException(msg))
    end

    return true
end

"""
    check_is_id(value; msg = nothing)

Check whether a value is a valid table prefixed ID, and stop if not

# Arguments
- `value`: A string value
- `msg`: A custom error message if the check fails

# Returns
- `true` if the value is a valid Epigraf ID
"""
function check_is_id(value; msg = nothing)
    if !epi_is_id(value)
        msg = !isnothing(msg) ? msg : "The value $(value) is not a valid Epigraf ID."
        throw(ErrorException(msg))
    end
    return true
end

"""
    check_is_db(value; msg = nothing)

Check whether a value is a valid database name, and stop if not

# Arguments
- `value`: A character value
- `msg`: A custom error message if the check fails

# Returns
- `true` if the value is a valid Epigraf database name
"""
function check_is_db(value; msg = nothing)
    if !isempty(value) && !(value isa AbstractString)
        msg = !isnothing(msg) ? msg : "The value $(value) is not a valid Epigraf database name."
        throw(ErrorException(msg))
    end
    return true
end
