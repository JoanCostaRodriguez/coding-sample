
required_pkgs <- c(
  "dplyr","tidyr","stringr","purrr","tibble","janitor",
  "readxl","openxlsx","readr",
  "stringdist",
  "here",
  "rmarkdown"   # for rendering the report from run_all.R
)

missing <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0) {
  stop(
    "Missing required packages: ", paste(missing, collapse = ", "), "\n\n",
    "Install with:\n",
    "install.packages(c(", paste0('"', missing, '"', collapse = ", "), "))\n",
    call. = FALSE
  )
}

suppressPackageStartupMessages(
  invisible(lapply(required_pkgs, library, character.only = TRUE))
)

