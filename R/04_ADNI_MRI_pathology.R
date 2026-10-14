source(file.path("R", "00_common.R"), encoding = "UTF-8")
mri <- data.table::fread(need_file("adni_mri_pathology.csv"), showProgress = FALSE)
need_columns(mri, c("participant_id", "ad_vulnerable_gm", "global_cortical_thickness", "hippocampal_icv_ratio", "wmh_brain_ratio", "amyloid_centiloid", "tau_temporal_suvr", "gMAV", "gMAV_noAPOE", "gAD_noAPOE", "APOE4", "age", "sex", "education", "scanner"), "adni_mri_pathology")
mri[, `:=`(APOE4 = assert_binary(APOE4, "APOE4"), sex = safe_factor(sex), scanner = safe_factor(scanner))]
outcomes <- c("ad_vulnerable_gm", "global_cortical_thickness", "hippocampal_icv_ratio", "wmh_brain_ratio")
exposures <- c("gMAV", "gMAV_noAPOE", "gAD_noAPOE", "APOE4")
fits <- list()
for (y in outcomes) for (x in exposures) {
  vars <- c(y, x, "age", "sex", "education", "scanner")
  d <- mri[complete.cases(mri[, ..vars])]
  if (nrow(d) < 20 || length(unique(d[[x]])) < 2) next
  fit <- stats::lm(stats::as.formula(paste(y, "~", paste(c(x, "age", "sex", "education", "scanner"), collapse = " + "))), data = d)
  sm <- summary(fit)$coefficients
  if (x %in% rownames(sm)) fits[[length(fits) + 1L]] <- data.table::data.table(outcome = y, exposure = x, n = nrow(d), estimate = sm[x, 1], standard_error = sm[x, 2], p_value = sm[x, 4])
}
write_csv(data.table::rbindlist(fits, fill = TRUE), "04_ADNI_MRI_pathology_models.csv")
write_lines("Structural indices are evaluated against genetic scores and pathology markers with scanner and demographic adjustment.", "04_ADNI_MRI_pathology_status.txt")
