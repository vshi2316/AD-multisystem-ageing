source(file.path("R", "00_common.R"), encoding = "UTF-8")
atvn <- data.table::fread(need_file("adni_atvn.csv"), showProgress = FALSE)
need_columns(atvn, c("participant_id", "time_years", "clinical_outcome", "gMAV", "gAD_noAPOE", "APOE4", "amyloid", "tau", "neurodegeneration", "age", "sex", "education"), "adni_atvn")
atvn[, `:=`(gMAV_z = zscore(gMAV), gAD_noAPOE_z = zscore(gAD_noAPOE), APOE4 = assert_binary(APOE4, "APOE4"), sex = safe_factor(sex))]
fits <- lapply(c("amyloid", "tau", "neurodegeneration", "clinical_outcome"), function(outcome) {
  f <- stats::as.formula(paste(outcome, "~ gMAV_z + gAD_noAPOE_z + APOE4 + age + sex + education + time_years"))
  fit <- stats::lm(f, data = atvn)
  out <- data.table::as.data.table(summary(fit)$coefficients, keep.rownames = "term")
  out[, `:=`(outcome = outcome, n = stats::nobs(fit), r_squared = summary(fit)$r.squared)]
  out[]
})
write_csv(data.table::rbindlist(fits, fill = TRUE), "03_ADNI_ATVN_expression_models.csv")
write_lines("A/T/N/V variables are modelled as prespecified biological and clinical expression endpoints with gMAV, gAD-noAPOE and APOE4 entered together.", "03_ADNI_ATVN_status.txt")
