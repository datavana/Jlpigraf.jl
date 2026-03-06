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
First, inform Jlpigraf of the Epigraf instance you wish to use and how you are authorized to do so.
An administrator has usually registered you and granted you the appropriate rights. You can find the token in your user profile. The example below uses a token for a test user.

``` julia
# Set token to get access to the API
api_setup("https://epigraf.uni-muenster.de","BC0YB9XVBGDFVOGNRWCP")

# Get an articles table
articles = fetch_table("articles"; db = "epi_movies", maxpages = 2)
```
`articles` holds a DataFrame with article data, corresponding to the top level of the Relational Article Model.

```
Fetched 20 records from articles.
20×3 DataFrame
 Row │ signature  name                      project_name 
     │ Int64      String31                  String7      
─────┼───────────────────────────────────────────────────
   1 │         1  2001: A Space Odyssey     Movies
   2 │         2  Spartacus                 Movies
   3 │         3  Gladiator                 Movies
   4 │         4  The Godfather             Movies
   5 │         5  Star Wars                 Movies
   6 │         6  Superbad                  Movies
   7 │         7  Pirates of the Caribbean  Movies
  ⋮  │     ⋮                 ⋮                   ⋮
  14 │         4  The Godfather             Movies
  15 │         5  Star Wars                 Movies
  16 │         6  Superbad                  Movies
  17 │         7  Pirates of the Caribbean  Movies
  18 │         8  The Lord of the Rings     Movies
  19 │         9  The Chronicles of Narnia  Movies
  20 │        10  La La Land                Movies
                                           6 rows omitted
```


More examples will be added as the functionality expands. 
See also [Rpigraf](https://github.com/datavana/rpigraf)'s documentation. 



