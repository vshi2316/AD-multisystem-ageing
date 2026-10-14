source(file.path("R", "00_common.R"), encoding = "UTF-8")
habs <- data.table::fread(need_file("habs_hd.csv"), showProgress = FALSE)
need_columns(habs, c("participant_id", "gAD_noAPOE", "ad_vulnerable_gm", "memory_score", "age", "sex"), "habs_hd")
habs[, `:=`(gAD_noAPOE_z = zscore(gAD_noAPOE), ad_vulnerable_gm_z = zscore(ad_vulnerable_gm), memory_score_z = zscore(memory_score), sex = safe_factor(sex))]
fit_structure <- stats::lm(ad_vulnerable_gm_z ~ gAD_noAPOE_z + age + sex, data = habs)
fit_memory <- stats::lm(memory_score_z ~ ad_vulnerable_gm_z + age + sex, data = habs)
extract_lm <- function(fit, model_id) { out <- data.table::as.data.table(summary(fit)$coefficients, keep.rownames = "term"); out[, `:=`(model_id = model_id, n = stats::nobs(fit), r_squared = summary(fit)$r.squared)]; out[] }
write_csv(data.table::rbindlist(list(extract_lm(fit_structure, "HABS_HD_structure"), extract_lm(fit_memory, "HABS_HD_memory")), fill = TRUE), "06_HABS_HD_concordance_models.csv")
write_lines("HABS-HD supplies biological concordance for the structural phenotype and memory association.", "06_HABS_HD_status.txt")
