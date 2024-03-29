### Run some simulations to see how often we're able to solve random menus without 
# doing any swapping at a certain minimum portion size ###

### Next, figure out the same if a certain number of swaps are allowed ###

# source("./scripts/solve.R")


# ----------------------------- Without Swapping ----------------------------------------------------------------

# --- Helper for getting the solve_it() status from a menu that has just been solved ---
get_status <- function(seed = NULL, min_food_amount = 0.5, verbose = TRUE) {  
  this_menu <- build_menu(seed = seed) %>% 
    solve_it(min_food_amount = min_food_amount, verbose = verbose, only_full_servings = FALSE) %>% 
    purrr::pluck("status")
}


# --- For a given minimum portion size, what proportion of a random number of simulated menus can we solve? ---
# 0 means that an optimal solution was found (because canonicalize_status is false)
simulate_menus <- function(n_sims = 10, min_food_amount = 0.5, verbose = FALSE) {
  
  # Choose as many random seeds as we have simulations
  seeds <- sample(1:n_sims, size = n_sims, replace = FALSE)
  
  out <- seeds %>% map2_dbl(.y = min_food_amount, .f = get_status)
  return(out)
}


# --- Simulate some number of times for each of some number of interval between two boundaries ---
# from is the lower bound for portion size and to is the upper bound
# n_intervals is the number of chunks we want to split the spectrum of from to to into
# n_sims is the number of times we want to repeat the simulation for each discrete interval
# Return a df showing the relationship between our minimum portion size (min_amount) vs. whether the menu could be solved
simulate_spectrum <- function(n_intervals = 10, n_sims = 2, from = -1, to = 1,
                              min_food_amount = NULL, verbose = FALSE, ...) {

  interval <- (to - from) / n_intervals
  spectrum <- seq(from = from, to = to, by = interval) %>% rep(n_sims) %>% sort()
  
  seeds <- sample(1:length(spectrum), size = length(spectrum), replace = FALSE)
  
  out_status <- vector(length = length(spectrum))
  
  for (i in seq_along(spectrum)) {
    this_status <- get_status(seed = seeds[i], min_food_amount = spectrum[i], verbose = verbose)
    if (!is.integer(this_status)) {
      this_status <- integer(0)     # If we don't get an integer value back, make it NA
    }
    out_status[i] <- this_status
  }
  
  out <- tibble(min_amount = spectrum, status = out_status)
  
  return(out)
}




# ----------------------------- With Swapping ----------------------------------------------------------------

# --- Build, swap, and solve a single menu, recording the status and number of swaps we did ---
# Analogous to get_status(), we build a random menu and see how many 
# swaps it takes to solve it, staying under the max number of swaps
# We return a tibble of the status and the number of swaps done
get_swap_status <- function(seed = NULL, min_food_amount = 0.5, max_n_swaps = 3, return_status = TRUE,
                           verbose = TRUE, ...) {  
  counter <- 0
  this_solution <- build_menu(seed = seed) %>% 
    solve_it(min_food_amount = min_food_amount, verbose = verbose, only_full_servings = FALSE) 
  
  this_status <- this_solution %>% purrr::pluck("status")
  
  this_menu <- this_solution %>% solve_menu()
  
  while (counter < max_n_swaps & this_status == 1) {
    this_solution <- this_menu %>% do_single_swap() %>% 
      solve_it(min_food_amount = min_food_amount, verbose = verbose, only_full_servings = FALSE)
    this_status <- this_solution %>% purrr::pluck("status")
    
    if (this_status == 0) {
      message(paste0("Solution found in ", counter, " steps"))
      if (return_status == TRUE) {
        out <- list(status = this_status, n_swaps_done = counter) %>% as_tibble()
        return(out)
      } else {
        this_menu <- this_solution %>% solve_menu()
        return(this_menu)
      }
    }
    counter <- counter + 1
  }
  
  message(paste0("No solution found in ", counter, " steps :/"))
  out <- tibble(status = this_status, n_swaps_done = counter)
  return(out)
}


# --- Simulate swapping and solving for a spectrum of minimum portion sizes with a fixed max number of swaps ---
# from is the lowest minimum portion size and to is the highest minimum portion size
# We split the range from:to into n_intervals and do n_sims at each interval
# For each simulation, we build a menu, try to solve it, and, if we can't, swap and solve as many times as we can until
# we either solve it and record the number of swaps it took or hit our max_n_swaps and record the failure
simulate_swap_spectrum <- function(n_intervals = 10, n_sims = 2, max_n_swaps = 3, from = -1, to = 1,
                                   seed = NULL, verbose = FALSE, ...) {
  
  interval <- (to - from) / n_intervals
  spectrum <- seq(from = from, to = to, by = interval) %>% rep(n_sims) %>% sort()
  
  if (!is.null(seed)) { set.seed(seed) }
  seeds <- sample(1:length(spectrum), size = length(spectrum), replace = FALSE)
  
  out_spectrum <- tibble(min_amount = spectrum)
  out_status <- tibble(status = vector(length = length(spectrum)), 
                       n_swaps_done = vector(length = length(spectrum)))
  
  for (i in seq_along(spectrum)) {
    this_status_df <- get_swap_status(seed = seeds[i], min_food_amount = spectrum[i], max_n_swaps = max_n_swaps, verbose = verbose)
    if (!is.integer(this_status_df$status)) {
      this_status_df$status <- integer(0)     # If we don't get an integer value back, make it NA
    }
    out_status[i, ] <- this_status_df
  }
  
  out <- bind_cols(out_spectrum, out_status)
  
  return(out)
}



# ----------------------------- Summarise ----------------------------------------------------------------

# --- Summarise a spectrum; eiher swapped or unswapped ---
# We can summarise either a vanilla status spectrum or a swap spectrum
summarise_status_spectrum <- function(spec) {
  
  # If this was a product of simulate_spectrum()
  if (!"n_swaps_done" %in% names(spec)){
    spec_summary <- spec %>% 
      group_by(min_amount) %>% 
      summarise(
        sol_prop = mean(status)
      )
    
    # If this was a product of simulate_swap_spectrum()
  } else {
    spec_summary <- spec %>% 
      group_by(min_amount) %>% 
      summarise(
        sol_prop = mean(status),
        mean_n_swaps_done = mean(n_swaps_done)
      )
  }
  
  return(spec_summary)
}



