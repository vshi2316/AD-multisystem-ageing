source(file.path("R", "00_common.R"), encoding = "UTF-8")
clinical <- data.table::fread(need_file("adni_clinical.csv"), showProgress = FALSE)
bridge <- data.table::fread(need_file("adni_cat12_bridge.csv"), showProgress = FALSE)
dat <- merge(clinical, bridge[, .(participant_id, cat12_vulnerability_z)], by = "participant_id")
dat <- dat[baseline_cn_mci == 1 & complete.cases(dat[, .(followup_years, dementia_event, cat12_vulnerability_z, age, sex, education, baseline_mmse, APOE4)])]
dat[, sex := safe_factor(sex)]
fit_base <- survival::coxph(survival::Surv(followup_years, dementia_event) ~ age + sex + education + baseline_mmse + APOE4, data = dat, x = TRUE, y = TRUE)
fit_struct <- survival::coxph(survival::Surv(followup_years, dementia_event) ~ age + sex + education + baseline_mmse + APOE4 + cat12_vulnerability_z, data = dat, x = TRUE, y = TRUE)
five_year_risk <- function(fit, d, horizon = 5) { bh <- survival::basehaz(fit, centered = FALSE); H0 <- max(bh$hazard[bh$time <= horizon], 0); if (!is.finite(H0) || H0 == 0) H0 <- max(bh$hazard, 0); 1 - exp(-H0 * exp(stats::predict(fit, newdata = d, type = "lp"))) }
dat[, `:=`(p_base = five_year_risk(fit_base, dat), p_struct = five_year_risk(fit_struct, dat))]
dat[, `:=`(y5 = as.integer(dementia_event == 1 & followup_years <= 5), evaluable5 = as.integer(followup_years >= 5 | (dementia_event == 1 & followup_years <= 5)))]
censor_fit <- survival::survfit(survival::Surv(followup_years, 1 - dementia_event) ~ 1, data = dat)
G_at <- function(t) { s <- summary(censor_fit, times = t, extend = TRUE)$surv; pmax(ifelse(length(s), s, 1), 1e-6) }
dat[evaluable5 == 1, ipcw5 := ifelse(y5 == 1, 1 / G_at(followup_years), 1 / G_at(5))]
eval <- dat[evaluable5 == 1]
auc <- function(y, p) { if (!requireNamespace("pROC", quietly = TRUE)) return(NA_real_); as.numeric(pROC::auc(pROC::roc(y, p, quiet = TRUE))) }
brier <- function(y, p, w) stats::weighted.mean((y - p)^2, w)
calibration <- function(y, p, w) { p <- pmin(pmax(p, 1e-6), 1 - 1e-6); fit <- stats::glm(y ~ qlogis(p), family = binomial(), weights = w); c(intercept = unname(stats::coef(fit)[1]), slope = unname(stats::coef(fit)[2])) }
cal_b <- calibration(eval$y5, eval$p_base, eval$ipcw5)
cal_s <- calibration(eval$y5, eval$p_struct, eval$ipcw5)
performance <- data.table::data.table(model = c("clinical_base", "clinical_plus_CAT12"), auc = c(auc(eval$y5, eval$p_base), auc(eval$y5, eval$p_struct)), brier = c(brier(eval$y5, eval$p_base, eval$ipcw5), brier(eval$y5, eval$p_struct, eval$ipcw5)), calibration_intercept = c(cal_b["intercept"], cal_s["intercept"]), calibration_slope = c(cal_b["slope"], cal_s["slope"]), n = nrow(eval), events_5y = sum(eval$y5))
set.seed(analysis_seed)
boot <- data.table::rbindlist(lapply(seq_len(bootstrap_B), function(b) { ii <- sample.int(nrow(eval), replace = TRUE); d <- eval[ii]; data.table::data.table(replicate = b, auc_base = auc(d$y5, d$p_base), auc_struct = auc(d$y5, d$p_struct), brier_base = brier(d$y5, d$p_base, d$ipcw5), brier_struct = brier(d$y5, d$p_struct, d$ipcw5)) }), fill = TRUE)
write_csv(performance, "05_ADNI_5y_performance.csv")
write_csv(boot, "05_ADNI_5y_bootstrap.csv")
write_lines("Five-year performance uses Cox-derived risks, inverse-censoring weights, discrimination, Brier score and calibration.", "05_ADNI_5y_performance_status.txt")
