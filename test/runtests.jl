using Revise, Pkg
using Jlpigraf
using Test

const setup_test_setup_file =  "./data/jlpigraf-setup-test.env";
const setup_file = "./data/jlpigraf-test.env";


#%% API functions
@testset "Jlpigraf.jl, API functions" begin
    # Write your tests here
    @test typeof(Jlpigraf.VERSION) == VersionNumber    

    # api_setup
    # - Test with explicit .env file, ENV empty
    api_clear_setup()
    test_env=joinpath(@__DIR__, setup_test_setup_file)    
    
    api_setup(settings_file=test_env)
    @test ENV["EPI_APISERVER"] == "https://test-server-294.de"
    @test ENV["EPI_APITOKEN"] == "testtoken-294"
    
    # - Test: use function arguments    
    api_setup("http://arg-1.de", "argtoken-1", settings_file=test_env)
    @test ENV["EPI_APISERVER"] == "http://arg-1.de"
    @test ENV["EPI_APITOKEN"] == "argtoken-1"
    
    api_clear_setup()
    @test !haskey(ENV, "EPI_APISERVER")
    @test !haskey(ENV, "EPI_APITOKEN")

        
end

nothing # cell result

#%% Functions fetching data

@testset "Jlpigraf.jl, fetch functions" begin
    test_env=joinpath(@__DIR__, setup_file)
    api_setup(settings_file=test_env)
    ENV["EPI_APISERVER"]

    articles = fetch_table("articles"; columns=[:id, :signature, :name], db = "epi_movies", maxpages = 2)
    @test length(articles.id) >= 10

end


nothing # cell result

#%% 
