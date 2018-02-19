
library(measurements)
library(feather)
more_recipes_df <- read_feather("./data/derived/more_recipes_df.feather")

more_recipes_df_head <- more_recipes_df %>% head()



# See what this does
conv_unit(more_recipes_df[3, ]$portion, more_recipes_df[3, ]$portion_abbrev, "g")


# What units are available?
conv_unit_options$volume


# Set up exception handling
try_conv <- possibly(conv_unit, otherwise = NA)

test_abbrev_dict_conv <- function(dict, key_col, val = 10) {
  
  quo_col <- enquo(key_col)
  
  out <- dict %>% 
    rowwise() %>% 
    mutate(
      converted_g = try_conv(val, !!quo_col, "g"),
      converted_ml = try_conv(val, !!quo_col, "ml"),
      converted = case_when(
        !is.na(converted_g) ~ converted_g,
        !is.na(converted_ml) ~ converted_ml
      )
    )
  
  return(out)
}
test_abbrev_dict_conv(abbrev_dict, key)


# We need to put the prefix "us_" before some of our units
to_usize <- c("tsp", "tbsp", "cup", "pint")   # "quart", "gal"

accepted <- c("oz", "pint", "lbs", "kg", "g", "l", "dl", "ml", "tbsp", "tsp", "cup", "oz")
accepted[which(accepted %in% to_usize)] <- stringr::str_c("us_", accepted[which(accepted %in% to_usize)])

# Let's cbind this to our dictionary 
abbrev_dict <- abbrev_dict %>% bind_cols(accepted = accepted)

# How about now?
test_abbrev_dict_conv(abbrev_dict, accepted)

convertables <- test_abbrev_dict_conv(abbrev_dict, accepted)


# What percent of 
length(convertables$converted[is.na(convertables$converted)]) / length(convertables$converted)








convert_units <- function(df, name_col = accepted, val_col = portion) {
  
  quo_name_col <- enquo(name_col)
  quo_val_col <- enquo(val_col)
  
  out <- df %>% 
    # left_join(abbrev_dict, by = c(!!quo_name_col, "key")) %>% 
    # na_if(!!quo_val_col == "") %>% 
    rowwise() %>% 
    mutate(
      converted_g = try_conv(!!quo_val_col, accepted, "g"),
      converted_ml = try_conv(!!quo_val_col, accepted, "ml"),
      converted = case_when(
        !is.na(converted_g) ~ converted_g,
        !is.na(converted_ml) ~ converted_ml
      )
    )
  
  return(out)
}

more_recipes_df_head <- more_recipes_df_head %>% 
  left_join(abbrev_dict, by = c("portion_abbrev" = "key"))


more_recipes_df_head %>% convert_units()
  


abbrev_dict %>% left_join(more_recipes_df_head, by = c("key" = "portion_abbrev")) %>% convert_units() %>% View()


more_recipes_df %>% 
  sample_n(30) %>% 
  mutate(
    foo = ifelse(portion_abbrev == "", "", conv_unit(portion, portion_abbrev, "g"))
  ) %>% View()




