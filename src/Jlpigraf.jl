module Jlpigraf


using DotEnv
using HTTP, URIs
using JSON3, CSV
using DataFrames

export api_setup, api_fetch, fetch_table

# parameters
const SETTINGS_FILE = "jlpigraf.env"
const VERSION=v"0.1.0-DEV"

include("api.jl")
include("fetch.jl")



end
