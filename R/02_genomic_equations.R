source(file.path("R", "00_common.R"), encoding = "UTF-8")

scores <- data.table::fread(need_file("genomic_scores.csv"), showProgress = FALSE)
need_columns(scores, c("participant_id", "gMAV", "gAD_noAPOE", "APOE4"), "genomic_scores")
scores[, APOE4 := assert_binary(APOE4, "APOE4")]
scores[, gMAV_z := zscore(gMAV)]
scores[, gAD_noAPOE_z := zscore(gAD_noAPOE)]

summary_tab <- data.table::fread(need_file("genomic_summary.csv"), showProgress = FALSE)
need_columns(summary_tab, c("trait", "estimate", "standard_error", "p_value"), "genomic_summary")

equations <- c(
  "Observed multisystem vulnerability: MAV_i = mean(Z_cardiometabolic,i, Z_sleep,i, Z_sensory,i, Z_physical,i).",
  "Genomic multisystem vulnerability: gMAV_i = sum_k w_MAV,k * G_i,k, with weights frozen before outcome modelling.",
  "APOE-independent AD score: gAD_noAPOE_i = gAD_raw_i - gamma_APOE * APOE4_i.",
  "Genomic SEM representation: X = Lambda F + epsilon; Sigma = Lambda Phi Lambda' + Theta.",
  "The genetic score analysis reports score construction, association, and uncertainty without asserting shared gMAV-AD architecture unless the supplied summary statistics support it."
)

cor_tab <- data.table::data.table(
  score = c("gMAV_z", "gAD_noAPOE_z"),
  mean = c(mean(scores$gMAV_z, na.rm = TRUE), mean(scores$gAD_noAPOE_z, na.rm = TRUE)),
  sd = c(sd(scores$gMAV_z, na.rm = TRUE), sd(scores$gAD_noAPOE_z, na.rm = TRUE)),
  n = c(sum(!is.na(scores$gMAV_z)), sum(!is.na(scores$gAD_noAPOE_z)))
)

write_csv(scores, "02_genomic_scores_standardised.csv")
write_csv(summary_tab, "02_genomic_summary_statistics.csv")
write_csv(cor_tab, "02_genomic_score_qc.csv")
write_lines(equations, "02_genomic_equations.txt")

sem_map_path <- file.path(data_dir, "genomic_sem_mapping.csv")
sem_cov_path <- file.path(data_dir, "genomic_covariance.csv")
if (file.exists(sem_map_path) && file.exists(sem_cov_path) && requireNamespace("lavaan", quietly = TRUE)) {
  sem_map <- data.table::fread(sem_map_path, showProgress = FALSE)
  sem_cov <- data.table::fread(sem_cov_path, showProgress = FALSE)
  need_columns(sem_map, c("trait", "factor"), "genomic_sem_mapping")
  if (nrow(sem_map) >= 3L && all(sem_map$trait %in% names(sem_cov))) {
    syntax <- paste(vapply(unique(sem_map$factor), function(f) paste0(f, " =~ ", paste(sem_map[factor == f, trait], collapse = " + ")), character(1)), collapse = "\n")
    trait_names <- sem_map$trait
    cov_mat <- as.matrix(sem_cov[, ..trait_names])
    rownames(cov_mat) <- sem_cov$trait
    fit <- lavaan::sem(syntax, sample.cov = cov_mat[trait_names, trait_names, drop = FALSE], sample.nobs = 100000, std.lv = TRUE)
    write_csv(data.table::as.data.table(lavaan::parameterEstimates(fit)), "02_genomic_sem_parameter_estimates.csv")
    write_lines(capture.output(summary(fit, fit.measures = TRUE, standardized = TRUE)), "02_genomic_sem_summary.txt")
  }
}
