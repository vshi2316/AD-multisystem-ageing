source(file.path("R", "00_common.R"), encoding = "UTF-8")

input_spec <- list(
  population_long = c("participant_id", "cohort", "age", "sex", "followup_years", "dementia_event", "cognitive_z", "mav_onset_year", "mav_cardiometabolic", "mav_sleep", "mav_sensory", "mav_physical"),
  population_event_long = c("participant_id", "cohort", "visit_year", "cognitive_z", "mav_onset_year", "age_baseline", "sex", "education", "event_route"),
  genomic_scores = c("participant_id", "gMAV", "gAD_noAPOE", "APOE4"),
  genomic_summary = c("trait", "estimate", "standard_error", "p_value"),
  adni_longitudinal = c("participant_id", "time_years", "ad_vulnerable_gm", "gMAV", "gAD_noAPOE", "age", "sex", "education", "diagnosis", "scanner"),
  adni_atvn = c("participant_id", "time_years", "clinical_outcome", "gMAV", "gAD_noAPOE", "APOE4", "amyloid", "tau", "neurodegeneration", "age", "sex", "education"),
  adni_mri_pathology = c("participant_id", "ad_vulnerable_gm", "global_cortical_thickness", "hippocampal_icv_ratio", "wmh_brain_ratio", "amyloid_centiloid", "tau_temporal_suvr", "gMAV", "gMAV_noAPOE", "gAD_noAPOE", "APOE4", "age", "sex", "education", "scanner"),
  adni_clinical = c("participant_id", "followup_years", "dementia_event", "baseline_cn_mci", "age", "sex", "education", "baseline_mmse", "APOE4"),
  habs_hd = c("participant_id", "gAD_noAPOE", "ad_vulnerable_gm", "memory_score", "age", "sex"),
  adni_cat12_bridge = c("participant_id", "cat12_vulnerability_z", "gAD_noAPOE", "gMAV", "followup_years", "dementia_event"),
  aibl_cat12_incident_ad = c("participant_id", "cat12_vulnerability_z", "followup_years", "incident_ad", "baseline_cn_mci", "age", "sex", "baseline_mmse", "APOE4")
)

validation <- data.table::rbindlist(lapply(names(input_spec), function(nm) {
  file_name <- paste0(nm, ".csv")
  path <- file.path(data_dir, file_name)
  if (!file.exists(path)) {
    return(data.table::data.table(file = file_name, exists = FALSE, nrow = NA_integer_, missing_columns = "file_missing"))
  }
  x <- data.table::fread(path, nrows = 1L, showProgress = FALSE)
  miss <- setdiff(input_spec[[nm]], names(x))
  data.table::data.table(file = file_name, exists = TRUE, nrow = nrow(data.table::fread(path, showProgress = FALSE)), missing_columns = paste(miss, collapse = ";"))
}), fill = TRUE)

write_csv(validation, "00_input_validation.csv")
if (any(!validation$exists) || any(nzchar(validation$missing_columns))) {
  stop("Input validation failed. See results/00_input_validation.csv.", call. = FALSE)
}

write_lines("All required public input tables are present and contain the declared columns.", "00_input_validation_status.txt")
