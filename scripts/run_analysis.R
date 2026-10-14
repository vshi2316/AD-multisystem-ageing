#!/usr/bin/env Rscript
.this_file <- (function() {
  args <- commandArgs(trailingOnly = FALSE)
  flag <- grep("^--file=", args, value = TRUE)
  if (length(flag)) return(sub("^--file=", "", flag[1L]))
  for (index in seq_len(sys.nframe())) {
    frame <- sys.frame(index)
    if (!is.null(frame$ofile)) return(frame$ofile)
  }
  file.path(getwd(), "scripts", "run_analysis.R")
})()
repo_root <- normalizePath(file.path(dirname(.this_file), ".."),
                           winslash = "/", mustWork = TRUE)
Sys.setenv(AD_MAV_REPO_ROOT = repo_root)
source(file.path(repo_root, "R", "run_all.R"), encoding = "UTF-8")
