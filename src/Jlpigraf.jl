module Jlpigraf


using DotEnv
using HTTP, URIs
using JSON3, CSV
using DataFrames

# Batch operations
export api_transfer

# Checks
export check_has_column, check_is_id, check_is_db

# Craft functions
export df_to_ram
export craft_projects, craft_articles, craft_sections, craft_items, craft_properties

# Database access
export db_setup, db_connect, db_name, db_databases, db_condition, db_table

# API
export api_setup, api_clear_setup, api_fetch

# Fetch
export fetch_table, fetch_entity

# Utils
export subset_by_col, merge_vectors, default_values

# Epigraf helpers
export epi_create_iri, epi_clean_irifragment, epi_is_iripath, epi_is_id, epi_is_prefixid
# Note: epi_is_irifragment is intentionally not exported as it's a helper for internal validation
export epi_iri_parent, epi_extract_long, epi_extract_wide, epi_wide_to_long

# parameters
const SETTINGS_FILE = "jlpigraf.env"
const VERSION = v"0.1.0-DEV"

include("utils.jl")
include("epi.jl")
include("api.jl")
include("checks.jl")
include("batch.jl")
include("fetch.jl")
include("craft.jl")
include("db.jl")



end
