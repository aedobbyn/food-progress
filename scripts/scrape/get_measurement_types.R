


get_measurement_types_from_source <- function() {
  
  measurement_url <- "https://www.convert-me.com/en/convert/cooking/"
  
  measurement_types_raw <- measurement_url %>% 
    read_html() %>% 
    html_nodes(".usystem") %>% 
    html_text()
  
  measurement_types <- measurement_types_raw %>% 
    str_replace_all("\n", "") %>% 
    str_replace_all("/", "") %>%
    str_replace_all("Units:" , "")  %>% 
    str_replace_all("U.S." , "")  %>% 
    str_replace_all("British" , "")  %>% 
    str_replace_all("\\(" , "") %>% 
    str_replace_all("\\)" , "")
  
  measurement_types <- measurement_types[1:2] # third contains no more information
  
  for (i in seq_along(measurement_types)) {
    measurement_types[i] <- substr(measurement_types[i], 42, nchar(measurement_types[i]))
  }
  
  measurement_types <- measurement_types %>% remove_whitespace() %>% 
    str_split(" ") %>% unlist() %>% map_chr(str_replace_all, "[[:space:]]", "") 
  measurement_types <- measurement_types[which(measurement_types != " " | measurement_types != "")] 
  measurement_types <- list(name = measurement_types) %>% as_tibble() %>% 
    distinct() %>% 
    filter(! name %in% c("dessert", "spoon", "fluid", "fl") & nchar(name) > 0) 
  
  # Add in things that didn't have abbreviations 
  needs_abbrev <- c("tablespoon", "teaspoon", "cup", "fluid ounce")
  abbrevs_needed <- c("tbsp", "tsp", "cup", "fluid oz")
  extra_measurements <- list(name = needs_abbrev, key = abbrevs_needed) %>% as_tibble()
  
  measurement_types <- measurement_types %>% filter(!name %in% needs_abbrev) 
  abbrev_dict <<- measurement_types %>%  mutate(
    rownum = 1:nrow(.),
    key = ifelse(rownum %% 2 != 0, lead(name), name)
  ) %>% 
    filter(!name == key) %>% 
    select(-rownum) 
  abbrev_dict <- abbrev_dict %>% bind_rows(extra_measurements)
  
  # measurement_types <- c(measurement_types, "fluid oz", "fl oz", "fluid ounce")
  
  return(measurement_types)
}


get_measurement_types_from_source_collapsed <- function() {
  
  measurement_types <- get_measurement_types_from_source()
  
  name_measures_collapsed <- abbrev_dict$name %>% str_c(collapse = "|")
  
  abbrev_dict$name %>% str_c(collapse = "\b") %>%
    str_split("\b") %>% str_c(collapse = "[[:digit:]]")
  
  vec_no_spaces <- vector()
  vec_w_spaces <- vector()
  for (i in abbrev_dict$key) {
    out_no_spaces <- c("[[:digit:]]", i, " ") %>% str_c(collapse = "")    # using " " instead of \b for word boundary
    out_w_spaces <- c("[[:digit:]] ", i, " ") %>% str_c(collapse = "")
    vec_no_spaces <- c(vec_no_spaces, out_no_spaces) 
    vec_w_spaces <- c(vec_w_spaces, out_w_spaces)
  }
  vec_no_spaces <- str_c(vec_no_spaces, collapse = "|")
  vec_w_spaces <- str_c(vec_w_spaces, collapse = "|")
  key_all <- str_c(vec_no_spaces, "|", vec_w_spaces, collapse = "|")
  measures_collapsed <- str_c(key_all, "|", name_measures_collapsed, collapse = "|")
  
  return(measures_collapsed)
}



get_measurement_types <- function(from_file = TRUE) {
  if (from_file == TRUE) {
    measures_collapsed <- read_rds("./data/measurement_types.rds")
  } else {
    measures_collapsed <- get_measurement_types_from_source_collapsed()
  }
  return(measures_collapsed)
}
