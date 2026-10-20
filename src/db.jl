#
# Functions for direct database access
#

# Conditionally load database packages
global MARIADB_AVAILABLE = true
try
    using MySQL
catch e
    global MARIADB_AVAILABLE = false
end

global DBINTERFACE_AVAILABLE = true
try
    using DBInterface
catch e
    global DBINTERFACE_AVAILABLE = false
end

"""
    db_setup(; host = "localhost", port = 3306, username = "root", password = "root", database = "")

Save database connection settings to environment variables.
Environment variables are prefixed with "epi_" and used in db_connect()
to establish the connection.

# Arguments
- `host`: Database host
- `port`: Database port
- `username`: Database username
- `password`: Database password
- `database`: Default database name
"""
function db_setup(; host = "localhost", port = 3306, username = "root", password = "root", database = "")
    ENV["epi_host"] = host
    ENV["epi_port"] = string(port)
    ENV["epi_username"] = username
    ENV["epi_password"] = password
    if !isempty(database)
        ENV["epi_dbname"] = database
    end
end

"""
    db_connect(db = nothing)

Get a connection to a database

Before you can use this function, call db_setup once
to set the connection parameters.
All parameters are stored in the environment.

# Arguments
- `db`: Name of the database as string.
       Leave empty to use the database name from the environment settings.

# Returns
- A database connection object
"""
function db_connect(db = nothing)
    if !@isdefined(MARIADB_AVAILABLE) || MARIADB_AVAILABLE == false
        throw(ErrorException("MariaDB package is required for database connectivity. Please install it with: import Pkg; Pkg.add(\"MariaDB\")"))
    end
    
    if isnothing(db)
        db = get(ENV, "epi_dbname", nothing)
    end

    if isnothing(db)
        throw(ErrorException("Database is not specified"))
    end

    host = get(ENV, "epi_host", "localhost")
    port = parse(Int, get(ENV, "epi_port", "3306"))
    username = get(ENV, "epi_username", "root")
    password = get(ENV, "epi_password", "root")    

    con = DBInterface.connect(MySQL.Connection, host, username, password; db = db, port = port)
    if isnothing(con) 
        throw(ErrorException("Could not connect to $(db)"))
    end

    return con
end

"""
    db_name(con)

Get the database name from a connection object

# Arguments
- `con`: A connection object

# Returns
- The database name as string
"""
function db_name(con)
    if !@isdefined(MARIADB_AVAILABLE) || MARIADB_AVAILABLE == false
        throw(ErrorException("MariaDB package is required. Please install it with: import Pkg; Pkg.add(\"MariaDB\")"))
    end
    return getproperty(con, :db)::String
end

"""
    db_databases(; epi = false)

Get list of all databases

# Arguments
- `epi`: Only keep databases with the epi-prefix

# Returns
- A DataFrame with database names
"""
function db_databases(; epi = false)
    if !@isdefined(MARIADB_AVAILABLE) || MARIADB_AVAILABLE == false
        throw(ErrorException("MariaDB package is required for database operations. Please install it with: import Pkg; Pkg.add(\"MariaDB\")"))
    end
    if !@isdefined(DBINTERFACE_AVAILABLE) || DBINTERFACE_AVAILABLE == false
        throw(ErrorException("DBInterface package is required for database operations. Please install it with: import Pkg; Pkg.add(\"DBInterface\")"))
    end
    
    con = db_connect()
    
    # Show databases query
    dbs = DBInterface.execute(con, "SHOW DATABASES;") |> DataFrame
    
    DBInterface.disconnect(con)

    if epi
        dbs = filter(:Database => d -> startswith(d, "epi_"), dbs)
    end

    return dbs
end

"""
    db_condition(table, field, value)

Construct filter conditions for the db_table() function

# Arguments
- `table`: Table name. Leave empty (nothing) to omit the table prefix.
- `field`: Field name
- `value`: A single value, a vector of strings or a vector of integers

# Returns
- A SQL condition string
"""
function db_condition(table, field, value)
    # Preprocess value(s) for SQL

    # If items in list are numeric --> collapse without quotes
    if !isempty(value) && all(x -> x isa Number, value)
        value_str = "(" * join(string.(value), ",") * ")"
    # If items in list are characters --> collapse with quotes
    elseif !isempty(value) && all(x -> x isa AbstractString, value)
        value_str = "('" * join(value, "','") * "')"
    else
        value_str = string(value)
    end

    # Create statement of type "col in list"
    if !isnothing(table)
        field = string(table) * "." * string(field)
    else
        field = string(field)
    end

    statement = string(field) * " in " * value_str
    return statement
end

"""
    db_table(table; cond = Dict{String, Any}(), deleted = false, compact = false, db = nothing)

Get data from a database table

# Arguments
- `table`: Table name
- `cond`: A dictionary of conditions
- `deleted`: Deleted records are skipped by default. Set to true, to get all records.
- `compact`: Whether to rename types columns to `type` and to add a `table` and a `database` column.
- `db`: A connection object or the database name (string).

# Returns
- A DataFrame with the query results
"""
function db_table(table, cond = Dict{String, Any}(); deleted = false, compact = false, db = nothing)
    cond = Dict{String, Any}(cond)
    if !@isdefined(MARIADB_AVAILABLE) || MARIADB_AVAILABLE == false
        throw(ErrorException("MariaDB package is required for database operations. Please install it with: import Pkg; Pkg.add(\"MariaDB\")"))
    end
    if !@isdefined(DBINTERFACE_AVAILABLE) || DBINTERFACE_AVAILABLE == false
        throw(ErrorException("DBInterface package is required for database operations. Please install it with: import Pkg; Pkg.add(\"DBInterface\")"))
    end
    
    # Check if db is character --> open db connection
    if db isa DBInterface.Connection
        con = db
        close_connection = false
    else
        con = db_connect(db)
        close_connection = true
    end


    # Construct SQL
    sql = "SELECT * FROM " * table

    # Add deleted = 0 to the conditions vector    
    if !deleted
        cond["deleted"] = "0"        
    end

    
    # Add all conditions to the query
    if !isempty(cond)
        cond = [sql_cond(p.first, p.second) for p in cond]
        cond_str = join(cond, " AND ")
        sql = sql * " WHERE " * cond_str
    end

    # Get table
    df = DBInterface.execute(con, sql) |> DataFrame

    # Set UTF-8 encoding for character columns
    for col in names(df)
        if eltype(df[!, col]) <: AbstractString
            df[!, col] = [x isa String ? x : "" for x in df[!, col]]
        end
    end

    if close_connection
        DBInterface.close(con)
    end

    if compact
        df[!, :table] .= table
        df[!, :database] .= isnothing(db) ? get(ENV, "epi_dbname", "") : (db isa AbstractString ? db : "")

        typecol = [col for col in names(df) if occursin(r"^[a-z]+type$" , string(col))]
        if length(typecol) == 1
            df[!, :type] = df[!, typecol[1]]
            select!(df, Not(typecol[1]))
        end
    end

    return df
end


"""
    sql_cond(field::S1, value::S2; op="=") where {S1<:AbstractString, S2<:AbstractString}
    sql_cond(field::S, value::T) where {S<:AbstractString, T<:Vector{Any}}

Return a string that can be part of an SQL-condition
"""
function sql_cond(field::S, value::T; op=" = ") where {S<:AbstractString, T<:Any}
    return "(" * field * op * sql_decorate(value) * ")"
end

function sql_cond(field::S, value_list::T) where {S<:AbstractString, T<:Vector{<:Any}}    
    return "(" * field * " in (" * join(sql_decorate.(value_list), ", ") * "))"
end

sql_decorate(v::Any) = "'" * string(v) * "'"
sql_decorate(v::Integer) = string(v)
