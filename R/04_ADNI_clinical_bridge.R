source(file.path("R", "00_common.R"), encoding = "UTF-8")
clinical <- data.table::fread(need_file("adni_clinical.csv"), showProgress = FALSE)
bridge <- data.table::fread(need_file("adni_cat12_bridge.csv"), showProgress = FALSE)
need_columns(clinical, c("participant_id", "followup_years", "dementia_event", "baseline_cn_mci", "age", "sex", "education", "baseline_mmse", "APOE4"), "adni_clinical")
need_columns(bridge, c("participant_id", "cat12_vulnerability_z"), "adni_cat12_bridge")
clinical[, `:=`(dementia_event = assert_binary(dementia_event, "dementia_event"), baseline_cn_mci = assert_binary(baseline_cn_mci, "baseline_cn_mci"), APOE4 = assert_binary(APOE4, "APOE4"), sex = safe_factor(sex))]
dat <- merge(clinical, bridge[, .(participant_id, cat12_vulnerability_z)], by = "participant_id")
dat <- dat[baseline_cn_mci == 1 & complete.cases(dat[, .(followup_years, dementia_event, cat12_vulnerability_z, age, sex, baseline_mmse, APOE4)])]
fit_base <- survival::coxph(survival::Surv(followup_years, dementia_event) ~ age + sex + education + baseline_mmse + APOE4, data = dat, x = TRUE, y = TRUE)
fit_struct <- survival::coxph(survival::Surv(followup_years, dementia_event) ~ age + sex + education + baseline_mmse + APOE4 + cat12_vulnerability_z, data = dat, x = TRUE, y = TRUE)
extract_cox <- function(fit, model_id) {
  sm <- summary(fit)
  out <- data.table::as.data.table(sm$coefficients, keep.rownames = "term")
  ci <- data.table::as.data.table(sm$conf.int, keep.rownames = "term")
  out <- merge(out, ci[, .(term, hazard_ratio = `exp(coef)`, conf_low = `lower .95`, conf_high = `upper .95`)], by = "term", all.x = TRUE)
  out[, `:=`(model_id = model_id, n = stats::nobs(fit), events = sum(fit$y[, 2]))]
  out[]
}
lrt <- stats::anova(fit_base, fit_struct, test = "LRT")
write_csv(data.table::rbindlist(list(extract_cox(fit_base, "ADNI_clinical_base"), extract_cox(fit_struct, "ADNI_clinical_plus_CAT12")), fill = TRUE), "04_ADNI_clinical_cox_coefficients.csv")
write_csv(data.table::data.table(model = rownames(lrt), lrt), "04_ADNI_structural_increment_lrt.csv")
write_lines("ADNI is analysed as a deep-phenotyping clinical bridge. The CAT12 structural term is evaluated as an increment to the prespecified clinical model.", "04_ADNI_clinical_bridge_status.txt")
