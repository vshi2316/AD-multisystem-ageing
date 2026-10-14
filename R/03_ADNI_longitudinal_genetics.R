source(file.path("R", "00_common.R"), encoding = "UTF-8")

adni <- data.table::fread(need_file("adni_longitudinal.csv"), showProgress = FALSE)
need_columns(adni, c("participant_id", "time_years", "ad_vulnerable_gm", "gMAV", "gAD_noAPOE", "age", "sex", "education", "diagnosis", "scanner"), "adni_longitudinal")
adni[, `:=`(gMAV_z = zscore(gMAV), gAD_noAPOE_z = zscore(gAD_noAPOE), ad_vulnerable_gm_z = zscore(ad_vulnerable_gm))]
adni[, `:=`(sex = safe_factor(sex), diagnosis = safe_factor(diagnosis), scanner = safe_factor(scanner))]

fit <- lme4::lmer(
  ad_vulnerable_gm_z ~ time_years * gAD_noAPOE_z + time_years * gMAV_z + age + sex + education + diagnosis + scanner + (1 + time_years | participant_id),
  data = adni,
  REML = FALSE
)
co <- data.table::as.data.table(lme4::fixef(fit), keep.rownames = "term")
co[, estimate := V1][, V1 := NULL]
vc <- as.matrix(stats::vcov(fit))
contrast <- data.table::data.table(
  contrast = "time:gAD_noAPOE - time:gMAV",
  estimate = fixef(fit)["time_years:gAD_noAPOE_z"] - fixef(fit)["time_years:gMAV_z"],
  standard_error = sqrt(vc["time_years:gAD_noAPOE_z", "time_years:gAD_noAPOE_z"] + vc["time_years:gMAV_z", "time_years:gMAV_z"] - 2 * vc["time_years:gAD_noAPOE_z", "time_years:gMAV_z"])
)
contrast[, `:=`(statistic = estimate / standard_error, p_value = 2 * stats::pnorm(-abs(statistic)), conf_low = estimate - 1.96 * standard_error, conf_high = estimate + 1.96 * standard_error)]

write_csv(co, "03_ADNI_longitudinal_fixed_effects.csv")
write_csv(contrast, "03_ADNI_gAD_vs_gMAV_time_contrast.csv")
write_lines("The primary longitudinal contrast tests whether the disease-specific gAD slope differs from the multisystem gMAV slope in the same mixed model.", "03_ADNI_longitudinal_status.txt")
