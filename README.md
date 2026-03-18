# Jlpigraf

The package is an API adapter for Epigraf. [Epigraf](https://github.com/digicademy/epigraf) is a proven tool for capturing, annotating, and publishing humanities corpora, which can be conceptualised as collections of articles. Epigraf provides a powerful API that can be used to query and modify project data. The [Rpigraf](https://github.com/datavana/rpigraf) package is available for conveniently querying project data via the API. Rpigraf's functions make it easier to filter and structure data. Jlpigraf translates Rpigraf into Julia. It provides data as DataFrames that can be used directly in other Julia packages for visualization or analysis.

The package is still in the early stages. However, the basic functions are already useful, and additional features will be added to the package gradually.

### Roadmap

| Version | Features |
| --- | --- |
| 0.1.0 | Basic API Interaction |
| 0.2.0 | Fetch tables and entities |
| 0.3.0 | Distill data from complex structures |
| 0.4.0 | Import/Update data in Epigraf |
| 0.5.0 | Batch processing |

## Installation
Get the package from GitHub:
``` julia
using Pkg
Pkg.add(url="https://github.com/zweiglimmergneis/Jlpigraf.jl.git")
using Jlpigraf

```
## API Documentation
See Epigraf's [documentation](https://epigraf.inschriften.net/help/coreconcepts/api) for a detailed description of the API. 

## Usage

### First steps
If you are not a registered user of an Epigraf instance, you can access a test version using the following credentials:  
URL: https://epigraf.uni-muenster.de  
Username: epitest  
Password: epitest.  
Logging in will give you an overview of the stored test data, e.g., displaying an article list: https://epigraf.uni-muenster.de/epi/epi_movies/articles.

To use the API, you first need to inform Jlpigraf of the Epigraf instance you wish to use, then authenticate with an API access token.
Usually, an administrator will have registered you and granted you the appropriate permissions.
You can find the access token in your user profile. The example below uses a token for the test user 'epitest'. 

``` julia
# Set token to get access to the API
api_setup("https://epigraf.uni-muenster.de", "testapitoken")

# Get an articles table
articles = fetch_table("articles"; columns=[:id, :signature, :name], db = "epi_movies", maxpages = 2)
```
`articles` holds a DataFrame with article data, corresponding to the top level of the Relational Article Model.

```
Fetched 10 records from articles.
10×3 DataFrame
 Row │ id           signature  name                     
     │ String15     Int64      String31
─────┼──────────────────────────────────────────────────
   1 │ articles-1           1  2001: A Space Odyssey
   2 │ articles-2           2  Spartacus
   3 │ articles-5           3  Gladiator
   4 │ articles-6           4  The Godfather
   5 │ articles-7           5  Star Wars
   6 │ articles-8           6  Superbad
   7 │ articles-9           7  Pirates of the Caribbean
   8 │ articles-10          8  The Lord of the Rings
   9 │ articles-11          9  The Chronicles of Narnia
  10 │ articles-12         10  La La Land
```

If you call `api_setup` without arguments, it will attempt to read the server and token data from a file called 'jlpigraf.env' in your working directory. If this file is not found, the function will prompt you for the required data. 'jlpigraf.env' could look like this:
```
EPI_APISERVER=https://epigraf.uni-muenster.de
EPI_APITOKEN=testapitoken
```

More examples will be added as the functionality expands. 
See also [Rpigraf](https://github.com/datavana/rpigraf)'s documentation. 



