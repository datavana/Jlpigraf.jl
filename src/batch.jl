#
# Functions for batch operations
#

"""
    api_transfer(table, db_source, db_target; db_params = Dict())

Transfer datasets between different databases

# Arguments
- `table`: Table name, e.g. "types"
- `db_source`: Source database name
- `db_target`: Target database name
- `db_params`: A dictionary of parameters for selecting the appropriate rows.
              For example: Dict("scopes" => "properties")
"""
function api_transfer(table, db_source, db_target; db_params = Dict())
    db_params["source"] = db_source
    api_job_create(string(table, "/transfer"), db_params, db_target)
end
