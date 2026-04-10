# Jlpigraf

The package is an API adapter for Epigraf. [Epigraf](https://github.com/digicademy/epigraf) is a proven tool for capturing, annotating, and publishing humanities corpora, which can be conceptualised as collections of articles. Epigraf provides a powerful API that can be used to query and modify project data. The [Rpigraf](https://github.com/datavana/rpigraf) package is available for conveniently querying project data via the API. Rpigraf's functions make it easier to filter and structure data. Jlpigraf translates Rpigraf into Julia. It provides data as DataFrames that can be used directly in other Julia packages for visualization or analysis.

The package is still in the early stages. However, the basic functions are already useful, and additional features will be added to the package gradually.

### Roadmap

| Version | Features | Status |
| --- | --- | --- |
| 0.1.0 | Basic API Interaction | 60 % |
| 0.2.0 | Fetch tables and entities | 20 % |
| 0.3.0 | Distill data from complex structures | |
| 0.4.0 | Import/Update data in Epigraf | |
| 0.5.0 | Batch processing | |

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

Call `api_setup` without arguments, to read the server and token data from a file called 'jlpigraf.env' in your working directory. If this file is not found, the function will prompt you for the required data. 'jlpigraf.env' could look like this:
```
EPI_APISERVER=https://epigraf.uni-muenster.de
EPI_APITOKEN=testapitoken
```

### Examine details in articles

The function `fetch_entity` accepts an ID or a list of IDs or a data frame with IDs and retrieves all entity data.

``` julia
db = "epi_movies"
entity_list = fetch_entity(articles, db=db) 
```

`entity_list` holds metadata in columns such as 'id', 'type', 'articles_id' and 'sections_id', as well a content in columns like 'name', 'lemma' and 'content'.

Epigraf uses the [Relational Article Model](https://epigraf.inschriften.net/help/coreconcepts/model) (RAL). 
Its structure determines the layout of `entity_list`.

For the following steps consider only three of the articles with the IDs: 'articles-5', 'articles-7', and 'articles-9'.
``` julia
id_list = ["articles-5", "articles-7", "articles-9"]
db = "epi_movies"
entity_list = fetch_entity(id_list; db=db)

# Show only parts of the data frame
cols = [:articles_id, :sections_id, :id, :type, :name, :content, :lemma]
select(entity_list, cols)[1:10]
```

```
10×7 DataFrame
 Row │ articles_id  sections_id  id            type        name       content                            lemma    
     │ String15?    String15?    String15      String15    String31?  String?                            String7?
─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ missing      missing      articles-5    default     Gladiator  missing                            missing
   2 │ missing      missing      projects-1    default     Movies     missing                            missing
   3 │ articles-5   missing      sections-10   text        Abstract   missing                            missing
   4 │ articles-5   sections-10  items-6       text        missing    Gladiator 🏟️ is a gripping tale o…  missing
   5 │ articles-5   missing      sections-9    categories  Genres     missing                            missing
   6 │ articles-5   sections-9   items-5       categories  missing    missing                            missing
   7 │ missing      missing      properties-1  categories  missing    missing                            History
   8 │ articles-5   missing      sections-48   images      Images     missing                            missing
   9 │ articles-5   sections-48  items-28      images      missing    missing                            missing
  10 │ missing      missing      articles-7    default     Star Wars  missing                            missing

```

Examine the descriptions by selecting 'content' in rows of the 'text' type:
``` julia

cols = [:articles_id, :sections_id, :type, :content];
description_list = subset(e_list[:, cols], :sections_id => ByRow(!ismissing), :type => ByRow(isequal("text")));
show(description_list, truncate=49)
```

```
3×4 DataFrame
 Row │ articles_id  sections_id  type      content
     │ String15?    String15?    String15  String?
─────┼─────────────────────────────────────────────────────────────────────────────────────────
   1 │ articles-5   sections-10  text      Gladiator 🏟️ is a gripping tale of power and reveng…
   2 │ articles-7   sections-14  text      Star Wars 🌌 is a monumental franchise set in a ga…
   3 │ articles-9   sections-18  text      Pirates of the Caribbean 🏴\u200d☠️ is a swashbuckl…
```

``` julia
description_list[2, :content]
```

> "Star Wars 🌌 is a monumental franchise set in a galaxy far, far away. The series blends elements of fantasy and sci-fi, featuring epic battles between the dark and light sides of the Force. Iconic characters like Luke Skywalker, Darth Vader, and Yoda are central to its storytelling. The franchise has expanded over decades, influencing multiple generations with its themes of heroism, redemption, and the struggle against tyranny. Star Wars remains a cultural phenomenon with a massive fanbase around the world."

### Access the RAL-Tree

The Relational Article Model is a nested structure. For example, an *article* contains *sections* with one or more *items*, that refer to a *property*.

The following example shows how to extract genre information for the movies.

Firstly, identify the relevant *sections* and join them to *items* of the 'categories' type. 
``` julia
genre_section_list = subset(e_list[:, [:id, :name, :articles_id]], :name => ByRow(isequal("Genres")))
item_list = subset(e_list[:, [:type, :sections_id, :property]], :type => ByRow(isequal("categories")))
genre_item_list = innerjoin(item_list, genre_section_list, on = :sections_id => :id, matchmissing = :notequal)

```

```
3×5 DataFrame
 Row │ type        sections_id  property       name       articles_id 
     │ String15    String15?    String15?      String31?  String15?
─────┼────────────────────────────────────────────────────────────────
   1 │ categories  sections-9   properties-1   Genres     articles-5
   2 │ categories  sections-13  properties-2   Genres     articles-7
   3 │ categories  sections-17  properties-12  Genres     articles-9
```

Join the property rows to the items.

``` julia
genre_list = innerjoin(e_list[:, [:id, :lemma]], genre_item_list, on = :id => :property)

```

```
3×6 DataFrame
 Row │ id             lemma     type        sections_id  name       articles_id
     │ String15       String7?  String15    String15?    String31?  String15?
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ properties-1   History   categories  sections-9   Genres     articles-5
   2 │ properties-2   Scifi     categories  sections-13  Genres     articles-7
   3 │ properties-12  Fantasy   categories  sections-17  Genres     articles-9

```


Join the title rows to the genre property rows.

``` julia
title_list = subset(e_list[:, [:id, :name]], :id => ByRow(startswith("articles")))

genre_title_list = innerjoin(
    title_list, 
    rename(genre_list[:, [:lemma, :id, :articles_id]], [:lemma => :genre, :id => :genre_id]),
    on = :id => :articles_id)
```

```
3×4 DataFrame
 Row │ id          name                      genre     genre_id
     │ String15    String31?                 String7?  String15
─────┼───────────────────────────────────────────────────────────────
   1 │ articles-5  Gladiator                 History   properties-1
   2 │ articles-7  Star Wars                 Scifi     properties-2
   3 │ articles-9  Pirates of the Caribbean  Fantasy   properties-12

```

The package includes features that automate the merging of different types of content. This greatly simplifies the process of working with data stored in Epigraf.

More examples will be added as additional functionality is implemented. 
See also [Rpigraf](https://github.com/datavana/rpigraf)'s documentation. 
