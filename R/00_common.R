# Shared helpers for the public analysis pipeline.
# Run scripts from the repository root or set AD_MAV_REPO_ROOT explicitly.

repo_root <- normalizePath(
  Sys.getenv("AD_MAV_REPO_ROOT", unset = getwd()),
  winslash = "/", mustWork = FALSE
)
input_dir <- Sys.getenv("AD_MAV_DATA_DIR", unset = "")
if (!nzchar(input_dir)) stop("Set AD_MAV_DATA_DIR to an external directory of authorized tables.", call. = FALSE)
data_dir <- normalizePath(input_dir, winslash = "/", mustWork = FALSE)
output_dir <- normalizePath(
  Sys.getenv("AD_MAV_OUTPUT_DIR", unset = file.path(repo_root, "results")),
  winslash = "/", mustWork = FALSE
)
analysis_seed <- as.integer(Sys.getenv("AD_MAV_SEED", unset = "20260914"))
bootstrap_B <- as.integer(Sys.getenv("AD_MAV_BOOTSTRAP_B", unset = "500"))
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

need_file <- function(name) {
  path <- if (grepl("[/\\\\]", name)) name else file.path(data_dir, name)
  if (!file.exists(path)) {
    stop("Required input is missing: ", normalizePath(path, winslash = "/", mustWork = FALSE), call. = FALSE)
  }
  path
}

need_columns <- function(x, cols, label) {
  missing <- setdiff(cols, names(x))
  if (length(missing)) {
    stop(label, " is missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  invisible(x)
}

num <- function(x) suppressWarnings(as.numeric(as.character(x)))

zscore <- function(x) {
  x <- num(x)
  m <- mean(x, na.rm = TRUE)
  s <- sd(x, na.rm = TRUE)
  if (!is.finite(s) || s <= 0) return(rep(NA_real_, length(x)))
  (x - m) / s
}

write_csv <- function(x, name) {
  data.table::fwrite(data.table::as.data.table(x), file.path(output_dir, name), na = "NA")
}

write_lines <- function(x, name) {
  writeLines(as.character(x), file.path(output_dir, name), useBytes = TRUE)
}

safe_factor <- function(x) factor(trimws(as.character(x)))

assert_binary <- function(x, label) {
  y <- num(x)
  if (any(!is.na(y) & !y %in% c(0, 1))) stop(label, " must be coded 0/1.", call. = FALSE)
  invisible(y)
}
