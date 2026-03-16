module Jlpigraf


using DotEnv
using HTTP, URIs
using JSON3, CSV
using DataFrames

export api_setup, api_fetch, fetch_table

# parameters
SETTINGS_FILE = "jlpigraf.env"

include("api.jl")
include("fetch.jl")

const version=v"0.1.0-DEV"

end
