source(file.path("R", "00_common.R"), encoding = "UTF-8")
aibl <- data.table::fread(need_file("aibl_cat12_incident_ad.csv"), showProgress = FALSE)
need_columns(aibl, c("participant_id", "cat12_vulnerability_z", "followup_years", "incident_ad", "baseline_cn_mci", "age", "sex", "baseline_mmse", "APOE4"), "aibl_cat12_incident_ad")
aibl[, `:=`(incident_ad = assert_binary(incident_ad, "incident_ad"), baseline_cn_mci = assert_binary(baseline_cn_mci, "baseline_cn_mci"), APOE4 = assert_binary(APOE4, "APOE4"), sex = safe_factor(sex))]
dat <- aibl[baseline_cn_mci == 1 & complete.cases(aibl[, .(followup_years, incident_ad, cat12_vulnerability_z, age, sex, baseline_mmse, APOE4)])]
fit <- survival::coxph(survival::Surv(followup_years, incident_ad) ~ cat12_vulnerability_z + age + sex + baseline_mmse + APOE4, data = dat, x = TRUE, y = TRUE)
sm <- summary(fit)
co <- data.table::as.data.table(sm$coefficients, keep.rownames = "term")
ci <- data.table::as.data.table(sm$conf.int, keep.rownames = "term")
co <- merge(co, ci[, .(term, hazard_ratio = `exp(coef)`, conf_low = `lower .95`, conf_high = `upper .95`)], by = "term", all.x = TRUE)
co[, `:=`(n = nrow(dat), events = sum(dat$incident_ad), endpoint = "incident_AD_after_baseline_CN_MCI")]
write_csv(co, "07_AIBL_incident_AD_cox_coefficients.csv")
write_csv(data.table::data.table(n = nrow(dat), events = sum(dat$incident_ad)), "07_AIBL_incident_AD_sample_flow.csv")
write_lines("AIBL uses the corrected incident-AD estimand: baseline CN/MCI participants only, with prevalent baseline AD excluded.", "07_AIBL_status.txt")
