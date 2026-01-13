suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(readxl)
  library(openxlsx)
  library(stringdist)
  library(tibble)
})

clean_names <- function(x) {
  str_to_upper(x) |>
    str_replace_all("[[:punct:]]", " ") |>
    str_squish()
}

assert_has_cols <- function(df, cols, df_name) {
  miss <- setdiff(cols, names(df))
  if (length(miss)) stop(df_name, " missing: ", paste(miss, collapse = ", "), call. = FALSE)
}

assert_unique <- function(df, col, df_name) {
  if (anyDuplicated(df[[col]])) stop(df_name, " has duplicates in '", col, "'.", call. = FALSE)
}

candidate_table <- function(unmatched_gdp, unmatched_pop, method = "osa", max_dist = 2, top_k = 5) {
  if (!nrow(unmatched_gdp) || !nrow(unmatched_pop)) return(tibble())
  
  D <- stringdistmatrix(unmatched_gdp$clean_name, unmatched_pop$clean_name, method = method)
  
  tibble::as_tibble(D) %>%
    mutate(gdp_row = row_number()) %>%
    pivot_longer(-gdp_row, names_to = "pop_col", values_to = "dist") %>%
    mutate(pop_row = as.integer(str_remove(pop_col, "^V"))) %>%
    select(gdp_row, pop_row, dist) %>%
    filter(dist <= max_dist) %>%
    left_join(unmatched_gdp %>% mutate(gdp_row = row_number()), by = "gdp_row") %>%
    left_join(unmatched_pop %>% mutate(pop_row = row_number()), by = "pop_row",
              suffix = c("_gdp", "_pop")) %>%
    group_by(code) %>%
    arrange(dist, municipality_pop) %>%
    slice_head(n = top_k) %>%
    ungroup() %>%
    transmute(
      code,
      municipality_gdp,
      clean_name_gdp,
      gdp_value,
      municipality_pop,
      clean_name_pop,
      population,
      state,
      dist
    )
}

choose_fuzzy_pairs <- function(cands) {
  if (!nrow(cands)) {
    return(tibble(code = character(), matched_pop_clean = character(), dist = numeric()))
  }
  
  cands <- cands %>% arrange(dist, code)
  
  used_codes <- character()
  used_pops  <- character()
  out <- vector("list", 0)
  
  for (i in seq_len(nrow(cands))) {
    row <- cands[i, ]
    code_i <- as.character(row$code)
    pop_i  <- as.character(row$clean_name_pop)
    
    if (code_i %in% used_codes || pop_i %in% used_pops) next
    
    used_codes <- c(used_codes, code_i)
    used_pops  <- c(used_pops, pop_i)
    out[[length(out) + 1]] <- row %>%
      transmute(code, matched_pop_clean = clean_name_pop, dist)
  }
  
  bind_rows(out)
}

match_gdp_pop_one_year <- function(
    gdp_path,
    pop_path,
    year_label,
    gdp_sheet = "Hoja1",
    gdp_code_col = "Codigo",
    gdp_muni_col = "Municipality",
    gdp_value_col = NULL,
    pop_muni_col = "Municipality",
    pop_pop_col  = "Population",
    pop_state_col = "State",
    method = "osa",
    max_dist = 2,
    top_k = 5,
    output_xlsx = NULL
) {
  
  gdp_raw <- read_excel(gdp_path, sheet = gdp_sheet)
  assert_has_cols(gdp_raw, c(gdp_code_col, gdp_muni_col, gdp_value_col), "GDP file")
  
  gdp <- gdp_raw %>%
    rename(
      code = all_of(gdp_code_col),
      municipality = all_of(gdp_muni_col),
      gdp_value = all_of(gdp_value_col)
    ) %>%
    mutate(
      municipality = as.character(municipality),
      clean_name = clean_names(municipality),
      gdp_value = as.numeric(gdp_value)
    )
  
  assert_unique(gdp, "code", "GDP data")
  
  pop_raw <- read_excel(pop_path)
  assert_has_cols(pop_raw, c(pop_muni_col, pop_pop_col, pop_state_col), "Population file")
  
  pop <- pop_raw %>%
    rename(
      municipality = all_of(pop_muni_col),
      population = all_of(pop_pop_col),
      state = all_of(pop_state_col)
    ) %>%
    mutate(
      municipality = as.character(municipality),
      clean_name = clean_names(municipality),
      population = as.numeric(population),
      state = as.character(state)
    )
  
  exact <- gdp %>%
    inner_join(pop, by = "clean_name", suffix = c("_gdp", "_pop")) %>%
    transmute(
      code,
      year = year_label,
      municipality = municipality_gdp,
      state,
      population,
      gdp_value,
      gdp_pc = gdp_value / population,
      match_type = "Exact",
      dist = NA_real_
    ) %>%
    filter(is.finite(gdp_pc), population > 0)
  
  unmatched_gdp <- gdp %>% anti_join(pop, by = "clean_name")
  unmatched_pop <- pop %>% anti_join(gdp, by = "clean_name")
  
  cands <- candidate_table(unmatched_gdp, unmatched_pop, method = method, max_dist = max_dist, top_k = top_k)
  chosen_pairs <- choose_fuzzy_pairs(cands)
  
  fuzzy <- chosen_pairs %>%
    left_join(gdp %>% select(code, municipality, gdp_value), by = "code") %>%
    left_join(pop %>% select(clean_name, municipality, population, state),
              by = c("matched_pop_clean" = "clean_name"),
              suffix = c("_gdp", "_pop")) %>%
    transmute(
      code,
      year = year_label,
      municipality = municipality_gdp,
      state,
      population,
      gdp_value,
      gdp_pc = gdp_value / population,
      match_type = "Fuzzy",
      dist
    ) %>%
    filter(is.finite(gdp_pc), population > 0)
  
  final_matched <- bind_rows(exact, fuzzy) %>%
    arrange(code) %>%
    distinct(code, .keep_all = TRUE)
  
  summary <- tibble(
    year = year_label,
    gdp_rows = nrow(gdp),
    pop_rows = nrow(pop),
    exact_matches = nrow(exact),
    fuzzy_matches = nrow(fuzzy),
    total_matched = nrow(final_matched),
    gdp_unmatched_dropped = nrow(gdp) - nrow(final_matched),
    candidate_rows = nrow(cands)
  )
  
  if (!is.null(output_xlsx)) {
    wb <- createWorkbook()
    addWorksheet(wb, "summary"); writeData(wb, "summary", summary)
    addWorksheet(wb, "matched_final"); writeData(wb, "matched_final", final_matched)
    addWorksheet(wb, "candidates_topk"); writeData(wb, "candidates_topk", cands)
    addWorksheet(wb, "chosen_pairs"); writeData(wb, "chosen_pairs", chosen_pairs)
    addWorksheet(wb, "unmatched_gdp_dropped"); writeData(wb, "unmatched_gdp_dropped", unmatched_gdp)
    saveWorkbook(wb, output_xlsx, overwrite = TRUE)
  }
  
  list(summary = summary, matched = final_matched)
}

