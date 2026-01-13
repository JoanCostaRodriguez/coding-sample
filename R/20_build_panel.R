
build_all_years <- function(PATHS) {
  
  jobs <- tibble::tribble(
    ~year, ~gdp_file,        ~gdp_value_col, ~pop_file,
    1940,  "gdp_1939.xlsx",  "1939",         "population_1940_clean.xlsx",
    1950,  "gdp_1950.xlsx",  "1949",         "population_1950_clean.xlsx",
    1960,  "gdp_1960.xlsx",  "1959",         "population_1960_clean.xlsx",
    1970,  "gdp_1970.xlsx",  "1970",         "population_1970_clean.xlsx",
    1976,  "gdp_1975.xlsx",  "1975",         "population_1976_clean.xlsx",
    1980,  "gdp_1980.xlsx",  "1980",         "population_1980_clean.xlsx",
    1996,  "gdp_1996.xlsx",  "1996",         "population_1992_clean.xlsx"
  ) %>%
    dplyr::mutate(
      gdp_path = file.path(PATHS$raw, gdp_file),
      pop_path = file.path(PATHS$raw, pop_file),
      out_xlsx = file.path(PATHS$tables, paste0("Municipality_Matching_", year, ".xlsx"))
    )
  
  # Ensure files exist
  purrr::walk(jobs$gdp_path, assert_file)
  purrr::walk(jobs$pop_path, assert_file)
  
  # Run matching year by year
  results <- jobs %>%
    dplyr::mutate(res = purrr::pmap(
      list(gdp_path, pop_path, gdp_value_col, year, out_xlsx),
      ~match_gdp_pop_one_year(
        gdp_path = ..1,
        pop_path = ..2,
        gdp_value_col = ..3,
        year_label = ..4,
        output_xlsx = ..5,
        max_dist = 2,
        top_k = 5,
        method = "osa"
      )
    ))
  
  summaries   <- dplyr::bind_rows(purrr::map(results$res, "summary"))
  matched_all <- dplyr::bind_rows(purrr::map(results$res, "matched"))
  
  list(summaries = summaries, matched_all = matched_all)
}
