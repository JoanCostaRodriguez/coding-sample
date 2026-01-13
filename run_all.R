
source(here::here("R", "00_packages.R"))
source(here::here("R", "01_paths.R"))
source(here::here("R", "10_matching.R"))
source(here::here("R", "20_build_panel.R"))
source(here::here("R", "30_checks.R"))
source(here::here("R", "40_sanity_plot.R"))


out <- build_all_years(PATHS = PATHS)


readr::write_csv(
  out$matched_all,
  file.path(PATHS$output, "matched_municipality_panel.csv")
)


readr::write_csv(
  out$summaries,
  file.path(PATHS$output, "matching_summary_by_year.csv")
)

check_tbl <- check_match_rates(out$summaries)
readr::write_csv(
  check_tbl,
  file.path(PATHS$output, "check_match_rates.csv")
)

make_sanity_plot_gdp_pc(
  out$matched_all,
  file.path(PATHS$figures, "sanity_log_gdp_pc_by_year.png")
)

message("Done.")
message("Panel:   ", file.path(PATHS$output, "matched_municipality_panel.csv"))
message("Summary: ", file.path(PATHS$output, "matching_summary_by_year.csv"))
message("Checks:  ", file.path(PATHS$output, "check_match_rates.csv"))
message("Plot:    ", file.path(PATHS$figures, "sanity_log_gdp_pc_by_year.png"))
