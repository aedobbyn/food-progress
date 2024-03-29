# Use the GNU solver linear program solver to get from a random menu to a compliant
# menu, if possible, by adjusting food portions
library(Rglpk)
library(stringr)
library(tidyverse)
# devtools::install_github("aedobbyn/dobtools", force = FALSE)
library(dobtools)

source("./helpers/helpers.R")
source("./scripts/build.R")   # Load all original menu building and tweaking functions but 
                              # only create the original menu (with seed = 9)

# Load solving scripts in /solve
import_scripts(path = "./scripts/solve")

# Label menu as per 100g
menu_unsolved_per_g <- menu

# Get raw weight of nutrients
menu_unsolved_raw <- get_raw_vals(menu_unsolved_per_g)  # Reverse with get_per_g_vals()

# Transpose menu
menu_transposed <- menu_unsolved_raw %>% get_per_g_vals() %>% transpose_menu()

# Run solve_it()
solution <- solve_it(menu_unsolved_raw, nutrient_df, df_is_per_100g = FALSE, min_food_amount = 0.5)
compliant_solution <- solve_it(menu_unsolved_per_g, nutrient_df, min_food_amount = -1)

# Solve nutrients
solved_nutrinets <- solution %>% solve_nutrients()
compliant_nutrinets <- compliant_solution %>% solve_nutrients()

# Run solve_menu()
solved_menu <- solution %>% solve_menu()
compliant_menu <- compliant_solution %>% solve_menu()

# Test compliance 
solved_menu %>% test_all_compliance_verbose()
compliant_menu %>% test_all_compliance_verbose()

# Swap a single 
solved_one_swap <- solved_menu %>% do_single_swap(verbose = TRUE)
compliant_one_swap <- compliant_menu %>% do_single_swap(verbose = TRUE)

# Score
score_menu(menu)
score_menu(solved_menu)
score_menu(compliant_one_swap)

# Full thing from beginning to end
out <- build_menu(abbrev, seed = 9) %>% 
  solve_it(nutrient_df, min_food_amount = -1) %>% 
  solve_menu() %>% 
  do_single_swap(verbose = FALSE)





