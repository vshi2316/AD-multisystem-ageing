source(file.path("R", "00_common.R"), encoding = "UTF-8")
events <- data.table::fread(need_file("population_event_long.csv"), showProgress = FALSE)
need_columns(events, c("participant_id", "cohort", "visit_year", "cognitive_z", "mav_onset_year", "age_baseline", "sex", "education", "event_route"), "population_event_long")
events[, `:=`(cohort = safe_factor(cohort), sex = safe_factor(sex), event_route = safe_factor(event_route))]
events[, time_from_onset := visit_year - mav_onset_year]
events <- events[complete.cases(events[, .(cognitive_z, time_from_onset, age_baseline, sex, education, event_route, participant_id)])]
fit <- lme4::lmer(cognitive_z ~ time_from_onset * event_route + visit_year + age_baseline + sex + education + (1 + time_from_onset | participant_id), data = events, REML = FALSE)
coef_tab <- data.table::as.data.table(lme4::fixef(fit), keep.rownames = "term")
coef_tab[, estimate := V1][, V1 := NULL]
write_csv(coef_tab, "01_population_event_study_fixed_effects.csv")
write_lines("The event-aligned model estimates route-specific cognitive trajectories around first observed MAV onset.", "01_population_event_study_status.txt")
