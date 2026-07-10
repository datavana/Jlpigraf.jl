using Revise, Pkg
using Jlpigraf
using Test


#%%
@testset "Jlpigraf tests" begin
    @test typeof(Jlpigraf.VERSION) == VersionNumber    

    @testset "API tests" begin
       include("api_tests.jl") 
    end
    
end;




#%% Functions fetching data

@testset "Jlpigraf.jl, fetch functions" begin
    test_env=joinpath(@__DIR__, setup_file)
    api_setup(settings_file=test_env)
    ENV["EPI_APISERVER"]

    articles = fetch_table("articles"; columns=[:id, :signature, :name], db = "epi_movies", maxpages = 2)
    @test length(articles.id) >= 10

end


nothing # cell result

