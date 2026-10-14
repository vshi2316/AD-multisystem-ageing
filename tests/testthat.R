if (!requireNamespace("testthat", quietly = TRUE)) {
  stop("Install testthat before running tests.", call. = FALSE)
}

.this_file <- (function() {
  args <- commandArgs(trailingOnly = FALSE)
  flag <- grep("^--file=", args, value = TRUE)
  if (length(flag)) return(sub("^--file=", "", flag[1L]))
  for (index in seq_len(sys.nframe())) {
    frame <- sys.frame(index)
    if (!is.null(frame$ofile)) return(frame$ofile)
  }
  file.path(getwd(), "tests", "testthat.R")
})()
repo_root <- normalizePath(file.path(dirname(.this_file), ".."),
                           winslash = "/", mustWork = TRUE)
Sys.setenv(REPO_ROOT = repo_root)
testthat::test_dir(file.path(repo_root, "tests", "testthat"),
                   reporter = "summary")
