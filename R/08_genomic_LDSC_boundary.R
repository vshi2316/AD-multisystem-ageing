source(file.path("R", "00_common.R"), encoding = "UTF-8")
summary_tab <- data.table::fread(need_file("genomic_summary.csv"), showProgress = FALSE)
need_columns(summary_tab, c("trait", "estimate", "standard_error", "p_value"), "genomic_summary")
if (!"genetic_correlation" %in% names(summary_tab)) summary_tab[, genetic_correlation := NA_real_]
if (!"genetic_correlation_se" %in% names(summary_tab)) summary_tab[, genetic_correlation_se := NA_real_]
if (!"ldsc_model" %in% names(summary_tab)) summary_tab[, ldsc_model := "not_supplied"]
write_csv(summary_tab[, .(trait, ldsc_model, genetic_correlation, genetic_correlation_se, estimate, standard_error, p_value)], "08_genomic_LDSC_boundary_table.csv")
write_lines(c("LDSC fields are reported only when supplied in the summary-statistics input.", "A missing genetic correlation remains missing and is not replaced by a score correlation.", "The analysis distinguishes polygenic-score transfer from evidence for shared genetic architecture."), "08_genomic_LDSC_boundary_status.txt")
