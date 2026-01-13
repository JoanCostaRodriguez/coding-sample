
ROOT <- here::here()

PATHS <- list(
  root    = ROOT,
  data    = file.path(ROOT, "data"),
  raw     = file.path(ROOT, "data", "raw"),
  output  = file.path(ROOT, "output"),
  tables  = file.path(ROOT, "output", "tables"),
  logs    = file.path(ROOT, "output", "logs"),
  figures = file.path(ROOT, "output", "figures")
)

dir.create(PATHS$output,  showWarnings = FALSE, recursive = TRUE)
dir.create(PATHS$tables,  showWarnings = FALSE, recursive = TRUE)
dir.create(PATHS$logs,    showWarnings = FALSE, recursive = TRUE)
dir.create(PATHS$figures, showWarnings = FALSE, recursive = TRUE)

p_raw     <- function(...) file.path(PATHS$raw, ...)
p_tables  <- function(...) file.path(PATHS$tables, ...)
p_logs    <- function(...) file.path(PATHS$logs, ...)
p_figures <- function(...) file.path(PATHS$figures, ...)

assert_file <- function(path) {
  if (!file.exists(path)) stop("File not found: ", path, call. = FALSE)
  invisible(TRUE)
}

message("Project root: ", PATHS$root)