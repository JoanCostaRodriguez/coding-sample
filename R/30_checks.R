check_match_rates <- function(summaries) {
  summaries %>%
    mutate(match_rate = total_matched / gdp_rows) %>%
    arrange(year)
}

write_log <- function(df, path) {
  readr::write_csv(df, path)
  invisible(TRUE)
}
