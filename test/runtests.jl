using Revise, Pkg
using Jlpigraf
using Test

# helper functions

#%%
@testset "Jlpigraf.jl, API functions" begin
    # Write your tests here
    @test typeof(Jlpigraf.VERSION) == VersionNumber    

    # api_setup
    # - Test with explicit .env file, ENV empty
    Jlpigraf.api_clear_setup()
    test_env=joinpath(@__DIR__, "./data/jlpigraf-test.env")    
    
    @test begin
        api_setup(settings_file=test_env)
        (ENV["EPI_APISERVER"] == "https://test-server-294.de") && (ENV["EPI_APITOKEN"] == "testtoken-294")     
    end

    # - Test: use function arguments    
    @test begin
        api_setup("http://arg-1.de", "argtoken-1", settings_file=test_env)
        (ENV["EPI_APISERVER"] == "http://arg-1.de") && (ENV["EPI_APITOKEN"] == "argtoken-1")     
    end

        
end

nothing # cell result

#%%
