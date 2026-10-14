source(file.path("R", "00_common.R"), encoding = "UTF-8")

population <- data.table::fread(need_file("population_long.csv"), showProgress = FALSE)
need_columns(population, c("participant_id", "cohort", "age", "sex", "followup_years", "dementia_event", "mav_cardiometabolic", "mav_sleep", "mav_sensory", "mav_physical"), "population_long")

domain_cols <- c("mav_cardiometabolic", "mav_sleep", "mav_sensory", "mav_physical")
population[, full_domain_n := rowSums(!is.na(.SD)), .SDcols = domain_cols]
population[, mav_score := rowMeans(.SD, na.rm = TRUE), .SDcols = domain_cols]
population[full_domain_n < 4L, mav_score := NA_real_]
population[, cardiometabolic_vulnerable := as.integer(mav_cardiometabolic >= 0.40)]
population[, sleep_vulnerable := as.integer(mav_sleep >= 0.50)]
population[, sensory_vulnerable := as.integer(mav_sensory >= 0.60)]
population[, physical_vulnerable := as.integer(mav_physical >= (2 / 7))]
population[, mav_vulnerable_domain_count := rowSums(.SD), .SDcols = c("cardiometabolic_vulnerable", "sleep_vulnerable", "sensory_vulnerable", "physical_vulnerable")]
population[full_domain_n < 4L, mav_vulnerable_domain_count := NA_real_]
population[, multisystem_vulnerability := as.integer(mav_vulnerable_domain_count >= 2)]
population[is.na(mav_vulnerable_domain_count), multisystem_vulnerability := NA_integer_]
population[, cohort := safe_factor(cohort)]
population[, sex := safe_factor(sex)]
population[, dementia_event := assert_binary(dementia_event, "dementia_event")]

cohort_roles <- data.table::data.table(
  cohort = c("CHARLS", "ELSA", "HRS", "MHAS", "SHARE"),
  role = c("cross-cultural validation", "independent replication", "primary discovery", "cross-cultural validation", "European transportability"),
  endpoint = c("first-detected dementia", "first-detected dementia", "first-detected dementia", "first-detected dementia", "first-detected dementia")
)

model_data <- population[complete.cases(population[, .(followup_years, dementia_event, mav_score, age, sex, cohort)])]
fit <- survival::coxph(survival::Surv(followup_years, dementia_event) ~ mav_score + age + sex + strata(cohort), data = model_data, x = TRUE, y = TRUE)
coef_tab <- data.table::as.data.table(summary(fit)$coefficients, keep.rownames = "term")
ci <- data.table::as.data.table(summary(fit)$conf.int, keep.rownames = "term")
coef_tab <- merge(coef_tab, ci[, .(term, hazard_ratio = `exp(coef)`, conf_low = `lower .95`, conf_high = `upper .95`)], by = "term", all.x = TRUE)

write_csv(population, "01_population_MAV_scored.csv")
write_csv(cohort_roles, "01_cohort_roles.csv")
write_csv(coef_tab, "01_population_MAV_cox.csv")
write_lines("The five-cohort analysis preserves cohort-specific endpoint context and uses gMAV as a harmonised risk score.", "01_population_MAV_status.txt")
