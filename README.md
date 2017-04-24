# Menu Builder

Various forays into 

## Workflow
* Scrape certain parts of the page using CSS selectors
  * Scrape a table and use it to create some visualizations of GDP data 
  * Scrape all of the text on the page and create word frequency wordclouds to see what words are mentioned most often on the page  

## Main Files
* `menu_builder.R` 
	* Source from `abbrev.R` which reads in the abbreviated version of the USDA food database and prepares it a bit
	* Add random foods recursively (1 serving size per food) until we reach 2300 calories (the daily minimum)
	* Loops through "must restricts" (i.e. macros that have an upper daily limit)
	    * If the daily value of that must restrict is over the max limit, swap out a random food for the "worst offender" until we're compliant
* `add_to_db.R`
	* Recursively sends GET requests to the USDA API (in chunks of max 1500 rows at a time), getting JSON in return
	* Tidy the JSON and that single chunk to a database (Postgres first, MySQL later)
	    * Using this method only one chunk is kept in memory at once