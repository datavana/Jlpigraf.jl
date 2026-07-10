# api_setup

const setup_test_setup_file =  "./data/jlpigraf-setup-test.env";
const setup_file = "./data/jlpigraf-test.env";

# - Test with explicit .env file, ENV empty
api_clear_setup()
test_env=joinpath(@__DIR__, setup_test_setup_file)    

api_setup(settings_file=test_env)
@test ENV["EPI_APISERVER"] == "https://test-server-294.de"
@test ENV["EPI_APITOKEN"] == "testtoken-294"

# - Test: use function arguments    
api_setup("http://test-server-298.de", "argtoken-1", settings_file=test_env)
@test ENV["EPI_APISERVER"] == "http://test-server-298.de"
@test ENV["EPI_APITOKEN"] == "argtoken-1"

# api_buildurl

scheme = "http"
host = "test-server-298.de"
path = "epi/endpoint.json"
query = "token=argtoken-1"

uri = Jlpigraf.URI(
    scheme = scheme,
    host = host,
    path = "/" * path,
    query = query
    )

built_url = Jlpigraf.api_buildurl("epi/endpoint")

@test isa(built_url, AbstractString)
@test Jlpigraf.URIs.URI(built_url) == uri

# Add query parameter
query = "token=argtoken-1&columns=col-1%2Ccol2&term=anno"

uri = Jlpigraf.URI(
    scheme = scheme,
    host = host,
    path = "/" * path,
    query = query
    )

built_uri_str = Jlpigraf.api_buildurl(
    "epi/endpoint", 
    Dict("columns" => "col-1,col2", "term" => "anno")
)

built_uri = Jlpigraf.URIs.URI(built_uri_str)

@test built_uri.scheme == uri.scheme
@test built_uri.host == uri.host
@test built_uri.path == uri.path
@test Jlpigraf.URIs.queryparams(built_uri) == Jlpigraf.URIs.queryparams(uri)

# Add database parameter
query = "token=argtoken-1"
database = "movies"

uri = Jlpigraf.URI(
    scheme = scheme,
    host = host,
    path = join(["/epi", database, "endpoint.json"], "/"),
    query = query
    )

built_uri_str = Jlpigraf.api_buildurl(
    "endpoint", 
    Dict{String, String}(),
    database,
)

built_uri = Jlpigraf.URIs.URI(built_uri_str)

@test built_uri.scheme == uri.scheme
@test built_uri.host == uri.host
@test built_uri.path == uri.path
# "/epi/movies/epi/endpoint.json" == "/epi/movies/endpoint.json"
@test Jlpigraf.URIs.queryparams(built_uri) == Jlpigraf.URIs.queryparams(uri)


api_clear_setup()
@test !haskey(ENV, "EPI_APISERVER")
@test !haskey(ENV, "EPI_APITOKEN")


