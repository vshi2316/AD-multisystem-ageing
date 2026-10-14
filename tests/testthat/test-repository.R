library(testthat)

test_that("public entry points and documentation are present", {
  root <- normalizePath(testthat::test_path("..", ".."), winslash = "/")
  required <- c(
    "README.md",
    "DESCRIPTION",
    "docs/data_dictionary.md",
    "docs/model_specification.md",
    "docs/code_inventory.md",
    "scripts/run_analysis.R",
    "scripts/run_figures.R",
    "R/run_all.R",
    "R/11_S7_covariance_aware_sensitivity_contrasts.R"
  )
  expect_true(all(file.exists(file.path(root, required))))
})

test_that("all public R scripts parse", {
  root <- normalizePath(testthat::test_path("..", ".."), winslash = "/")
  files <- list.files(file.path(root, "R"), pattern = "\\.R$", full.names = TRUE)
  files <- c(files, list.files(file.path(root, "scripts"), pattern = "\\.R$", full.names = TRUE))
  expect_gt(length(files), 0L)
  for (file in files) expect_no_error(parse(file = file))
})
