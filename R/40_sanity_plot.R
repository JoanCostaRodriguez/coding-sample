
make_sanity_plot_gdp_pc <- function(matched_all, out_path) {
  
  df <- matched_all %>%
    dplyr::filter(is.finite(gdp_pc), gdp_pc > 0) %>%
    dplyr::mutate(
      year = as.factor(year),
      log_gdp_pc = log(gdp_pc)
    )
  
  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
  
  png(out_path, width = 1200, height = 700, res = 150)
  boxplot(
    log_gdp_pc ~ year,
    data = df,
    main = "Sanity check: log(GDP per capita) by year",
    xlab = "Year",
    ylab = "log(GDP per capita)",
    las = 2
  )
  dev.off()
}