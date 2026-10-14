options(stringsAsFactors = FALSE, scipen = 999)
suppressPackageStartupMessages({
  library(data.table)
  library(lme4)
})

source_files <- vapply(sys.frames(), function(frame) {
  if (exists("ofile", envir = frame, inherits = FALSE)) {
    as.character(get("ofile", envir = frame, inherits = FALSE))[1L]
  } else {
    ""
  }
}, character(1))
source_files <- source_files[nzchar(source_files)]
script_file <- if (length(source_files)) tail(source_files, 1L) else {
  arguments <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(arguments)) sub("^--file=", "", arguments[1L]) else ""
}
if (!nzchar(script_file)) stop("Run this file with source() or Rscript.")

project_dir <- dirname(dirname(normalizePath(script_file, winslash = "/", mustWork = TRUE)))
frozen_results_dir <- Sys.getenv(
  "AD_MAV_FROZEN_RESULTS_ROOT",
  unset = file.path(project_dir, "results")
)
output_root <- Sys.getenv(
  "AD_MAV_OUTPUT_DIR",
  unset = file.path(project_dir, "results")
)
frozen_results_dir <- normalizePath(frozen_results_dir, winslash = "/", mustWork = FALSE)
output_root <- normalizePath(output_root, winslash = "/", mustWork = FALSE)
output_dir <- file.path(output_root, "13L_S7_covariance_aware_sensitivity_contrasts")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
success_file <- file.path(output_dir, "03_success_marker.txt")
if (file.exists(success_file)) unlink(success_file)
audit_file <- file.path(output_dir, "00_reproduction_audit.csv")
if (file.exists(audit_file)) unlink(audit_file)

required_file <- function(...) {
  path <- file.path(frozen_results_dir, ...)
  if (!file.exists(path)) stop("Required frozen input is missing: ", path, call. = FALSE)
  path
}
numeric_value <- function(value) suppressWarnings(as.numeric(as.character(value)))
finite_value <- function(value) is.finite(numeric_value(value))
standardize <- function(value) {
  value <- numeric_value(value)
  (value - mean(value, na.rm = TRUE)) / sd(value, na.rm = TRUE)
}
varies <- function(value) {
  if (is.factor(value)) return(nlevels(droplevels(value)) >= 2L)
  length(unique(value[!is.na(value) & is.finite(numeric_value(value))])) >= 2L
}
first_nonmissing <- function(value, numeric = FALSE) {
  if (numeric) {
    values <- numeric_value(value)
    return(if (any(is.finite(values))) values[which(is.finite(values))[1L]] else NA_real_)
  }
  values <- as.character(value)
  values <- values[!is.na(values) & nzchar(values)]
  if (length(values)) values[1L] else NA_character_
}

frame_file <- required_file("13F_R_only_structural_analysis",
                            "04_ADNI_R_only_longitudinal_structural_frame.rds")
pgs_file <- required_file("10A_ADNI_gMAV_PGS_assembly",
                          "02_ADNI_gMAV_gAD_PGS_longitudinal_clinical.tsv")
flags_file <- required_file("13F_automated_raw_T1_QC_and_processing_manifest",
                            "04_automatic_QC_flagged_images.csv")
frozen_file <- required_file("13F_final_revised_results",
                             "01_ADNI_primary_and_sensitivity_key_terms.csv")
other_file <- required_file("13F_R1_final_analysis", "01_model_coefficients.csv")
diagnostics_file <- required_file("13F_R1_final_analysis", "02_model_diagnostics.csv")
primary_file <- required_file("13K_core_claim_completion",
                              "01_gAD_vs_gMAV_direct_slope_contrast.csv")

data <- as.data.table(readRDS(frame_file))
data[, `:=`(RID = as.character(RID),
           mri_date = as.IDate(as.character(mri_date)),
           gMAV = numeric_value(clinical_gMAV_noAPOE_z_eur),
           gAD = numeric_value(clinical_gAD_noAPOE_z_eur),
           age_mri = numeric_value(age_mri))]
pgs <- fread(pgs_file, sep = "\t", showProgress = FALSE)
pgs[, `:=`(RID = as.character(RID),
           exam_date__ = as.IDate(as.character(EXAMDATE)))]
setorder(pgs, RID, exam_date__)
baseline <- pgs[, .(baseline_age = first_nonmissing(age_bl, TRUE),
                    baseline_sex = first_nonmissing(sex),
                    baseline_education = first_nonmissing(education, TRUE),
                    baseline_diagnosis = first_nonmissing(dx_bl)), by = RID]
data <- merge(data, baseline, by = "RID", all.x = TRUE, sort = FALSE)
data[, `:=`(baseline_age = numeric_value(baseline_age),
           sex = factor(baseline_sex),
           education = numeric_value(baseline_education),
           diagnosis = factor(baseline_diagnosis),
           scanner = factor(paste(FIELD_STRENGTH, FSVER, sep = "_")))]
pc_columns <- paste0("clinical_PC", 1:10)
for (column in pc_columns) {
  if (column %in% names(data)) data[, (column) := numeric_value(get(column))]
}
flags <- fread(flags_file, showProgress = FALSE)
flagged_rids <- unique(as.character(flags[cohort == "ADNI", RID]))
data[, raw_auto_flagged_participant := RID %in% flagged_rids]
data[, primary_complete := finite_value(ad_vulnerable_index)]
setorderv(data, c("RID", "mri_date", "primary_complete", "IMAGEUID"),
          order = c(1L, 1L, -1L, -1L), na.last = TRUE)
data <- data[, .SD[1L], by = .(RID, mri_date)]
setorder(data, RID, mri_date)
data[, first_mri_date := min(mri_date), by = RID]
data[, time_years := as.numeric(mri_date - first_mri_date) / 365.25]
data[, age_mri := baseline_age + time_years]
data[, `:=`(ad_vulnerable_z = standardize(ad_vulnerable_index),
           global_cortical_z = standardize(global_cortical_thickness))]
data <- data[finite_value(ad_vulnerable_z) & finite_value(gMAV) &
             finite_value(gAD) & !is.na(mri_date)]
no_spacing <- data[RID %in% data[, .(n_dates = uniqueN(mri_date)),
                                  by = RID][n_dates >= 2L, RID]]
eligibility <- no_spacing[, .(n_dates = uniqueN(mri_date),
                              second_date_270d = {
                                dates <- sort(unique(mri_date))
                                later <- dates[as.integer(dates - dates[1L]) >= 270L]
                                if (length(later)) later[1L] else as.IDate(NA)
                              }), by = RID]
primary <- no_spacing[RID %in% eligibility[
  n_dates >= 2L & !is.na(second_date_270d), RID]]

frozen <- fread(frozen_file, showProgress = FALSE)
other <- fread(other_file, showProgress = FALSE)
frozen_diagnostics <- fread(diagnostics_file, showProgress = FALSE)
primary_reference <- fread(primary_file, showProgress = FALSE)
covariate_names <- c("baseline_age", "sex", "education", "diagnosis",
                     "scanner", pc_columns)
specifications <- data.table(
  specification = c("Primary", "Exclude raw-image anomaly flags (270-day rule)",
                    "Without baseline diagnosis", "No 270-day spacing rule",
                    "Exclude raw-image anomaly flags (no spacing rule)",
                    "Global cortical thickness"),
  model_id = c("PRIMARY__ad_vulnerable_z__time_interaction",
               "EXCLUDE_RAW_AUTO_FLAGGED__ad_vulnerable_z__time_interaction",
               "WITHOUT_BASELINE_DIAGNOSIS__ad_vulnerable_z__time_interaction",
               "NO270__ad_vulnerable_z__time_interaction",
               "NO270_EXCLUDE_RAW_AUTO_FLAGGED__ad_vulnerable_z__time_interaction",
               "PRIMARY__global_cortical_z__time_interaction"),
  outcome = c(rep("ad_vulnerable_z", 5L), "global_cortical_z"),
  evidence_role = c("primary", rep("sensitivity", 4L), "secondary_endpoint")
)

fit_specification <- function(index) {
  specification <- specifications[index]
  sample <- if (index %in% c(4L, 5L)) copy(no_spacing) else copy(primary)
  if (index %in% c(2L, 5L)) sample <- sample[raw_auto_flagged_participant == FALSE]
  omitted <- if (index == 3L) "diagnosis" else character()
  covariates <- setdiff(covariate_names, omitted)
  covariates <- covariates[covariates %in% names(sample)]
  covariates <- covariates[vapply(covariates, function(column) {
    varies(sample[[column]])
  }, logical(1))]
  rhs <- paste(c("time_years * gMAV", "time_years * gAD", covariates),
               collapse = " + ")
  variables <- unique(c(specification$outcome, "RID", "time_years",
                        all.vars(as.formula(paste("~", rhs)))))
  model_data <- droplevels(sample[complete.cases(sample[, ..variables])])
  slope_formula <- as.formula(paste0(specification$outcome, " ~ ", rhs,
                                     " + (1 + time_years | RID)"))
  intercept_formula <- as.formula(paste0(specification$outcome, " ~ ", rhs,
                                         " + (1 | RID)"))
  control <- lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 200000))
  model <- tryCatch(lmer(slope_formula, data = model_data, REML = FALSE,
                         control = control), error = identity)
  random_structure <- "random_intercept_and_time_slope"
  if (inherits(model, "error") || isSingular(model, tol = 1e-4)) {
    model <- lmer(intercept_formula, data = model_data, REML = FALSE,
                  control = control)
    random_structure <- "random_intercept_fallback"
  }
  coefficients <- fixef(model)
  covariance <- as.matrix(vcov(model))
  terms <- c("time_years:gAD", "time_years:gMAV")
  if (!all(terms %in% names(coefficients))) {
    stop("Required interaction terms are missing in ", specification$model_id)
  }
  reference <- if (index == 6L) other[model_id == specification$model_id &
                                       term %in% terms] else
    frozen[model_id == specification$model_id & term %in% terms]
  if (nrow(reference) != 2L ||
      any(reference$n_people != uniqueN(model_data$RID)) ||
      any(reference$n_rows != nrow(model_data)) ||
      any(reference$random_structure != random_structure)) {
    stop("Frozen sample or model structure did not reproduce: ",
         specification$model_id)
  }
  for (term_name in terms) {
    expected <- reference[reference[["term"]] == term_name]
    if (nrow(expected) != 1L) {
      stop("Frozen result lacks one row for ", specification$model_id,
           ", ", term_name)
    }
    current_se <- sqrt(covariance[term_name, term_name])
    audit <- data.table(
      model_id = specification$model_id,
      term = term_name,
      actual_estimate = unname(coefficients[term_name]),
      frozen_estimate = expected$estimate,
      estimate_difference = unname(coefficients[term_name] - expected$estimate),
      actual_standard_error = current_se,
      frozen_standard_error = expected$std_error,
      standard_error_difference = current_se - expected$std_error,
      actual_log_likelihood = as.numeric(logLik(model)),
      frozen_log_likelihood = frozen_diagnostics[
        model_id == specification$model_id, logLik][1L],
      n_people = uniqueN(model_data$RID),
      n_MRI_rows = nrow(model_data),
      covariates = paste(covariates, collapse = "; "),
      random_structure = random_structure,
      R_version = R.version.string,
      lme4_version = as.character(packageVersion("lme4"))
    )
    fwrite(audit, audit_file, append = file.exists(audit_file),
           col.names = !file.exists(audit_file), bom = !file.exists(audit_file))
    if (abs(audit$estimate_difference) > 0.00001 ||
        abs(audit$standard_error_difference) > 0.00001) {
      stop("Frozen model mismatch: ", specification$model_id,
           ", ", term_name, "; estimate actual=", signif(audit$actual_estimate, 9L),
           ", frozen=", signif(audit$frozen_estimate, 9L),
           "; SE actual=", signif(audit$actual_standard_error, 9L),
           ", frozen=", signif(audit$frozen_standard_error, 9L),
           ". Diagnostics: ", audit_file)
    }
  }
  estimate <- unname(coefficients[terms[1L]] - coefficients[terms[2L]])
  cross_covariance <- covariance[terms[1L], terms[2L]]
  standard_error <- sqrt(covariance[terms[1L], terms[1L]] +
                           covariance[terms[2L], terms[2L]] -
                           2 * cross_covariance)
  result <- data.table(
    specification = specification$specification,
    evidence_role = specification$evidence_role,
    model_id = specification$model_id,
    outcome = specification$outcome,
    contrast = "time_years:gAD minus time_years:gMAV",
    estimate_difference_SD_per_year = estimate,
    covariance_between_interactions = cross_covariance,
    standard_error = standard_error,
    conf_low = estimate - 1.96 * standard_error,
    conf_high = estimate + 1.96 * standard_error,
    z_value = estimate / standard_error,
    p_value = 2 * pnorm(-abs(estimate / standard_error)),
    n_people = uniqueN(model_data$RID),
    n_MRI_rows = nrow(model_data),
    random_structure = random_structure,
    singular = isSingular(model, tol = 1e-4),
    convergence_message = paste(model@optinfo$conv$lme4$messages,
                                collapse = " | "),
    confidence_interval_excludes_zero =
      (estimate - 1.96 * standard_error) *
      (estimate + 1.96 * standard_error) > 0
  )
  if (index == 1L && (
      abs(result$estimate_difference_SD_per_year -
            primary_reference$estimate_difference_SD_per_year[1L]) > 0.00001 ||
      abs(result$standard_error - primary_reference$standard_error[1L]) > 0.00001 ||
      abs(result$p_value - primary_reference$p_value[1L]) > 0.00001)) {
    stop("The primary direct contrast did not reproduce the frozen 13K result.")
  }
  message(specification$specification, ": n=", result$n_people,
          ", MRI=", result$n_MRI_rows,
          ", difference=", signif(estimate, 5L),
          ", P=", signif(result$p_value, 4L))
  result
}

results <- rbindlist(lapply(seq_len(nrow(specifications)), fit_specification))
fwrite(results, file.path(output_dir, "01_S7_direct_slope_sensitivity_contrasts.csv"),
       bom = TRUE, na = "NA")
writeLines(capture.output(sessionInfo()), file.path(output_dir, "02_sessionInfo.txt"))
writeLines("S7_DIRECT_CONTRAST_OK: six models reproduced frozen component estimates and primary direct contrast.",
           success_file)
message("Results: ", file.path(output_dir, "01_S7_direct_slope_sensitivity_contrasts.csv"))
