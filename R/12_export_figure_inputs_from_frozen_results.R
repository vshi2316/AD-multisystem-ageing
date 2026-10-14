source(file.path("R", "00_common.R"), encoding = "UTF-8")

frozen_root <- Sys.getenv("AD_MAV_FROZEN_RESULTS_ROOT", unset = "")
if (!nzchar(frozen_root)) stop("Set AD_MAV_FROZEN_RESULTS_ROOT to the directory containing the frozen result folders.", call. = FALSE)
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
need_result <- function(...) {
  p <- file.path(frozen_root, ...)
  if (!file.exists(p)) stop("Frozen result is missing: ", p, call. = FALSE)
  p
}

traj <- data.table::fread(need_result("13K_core_claim_completion", "03_standardized_predicted_trajectories.csv"), showProgress = FALSE)
need_columns(traj, c("panel", "time_years", "predicted_change_z"), "standardized_predicted_trajectories")
traj[, `:=`(model = "ADNI structural trajectory", estimate = predicted_change_z, conf_low = NA_real_, conf_high = NA_real_, group = panel)]
data.table::fwrite(traj[, .(model, time_years, estimate, conf_low, conf_high, group)], file.path(data_dir, "figure_trajectories.csv"), na = "NA")

aibl <- data.table::fread(need_result("13K_core_claim_completion", "08_AIBL_ADNI_frozen_CAT12_incident_AD_models.csv"), showProgress = FALSE)
need_columns(aibl, c("term", "hazard_ratio", "conf_low", "conf_high", "p_value"), "AIBL incident-AD models")
data.table::fwrite(aibl, file.path(data_dir, "figure_aibl_models.csv"), na = "NA")

mri <- data.table::fread(need_result("12D_ADNI_PGS_structural_MRI_pathology_models", "01_genetic_structural_MRI_main_effects.csv"), showProgress = FALSE)
need_columns(mri, c("outcome", "exposure", "estimate", "conf_low", "conf_high", "p_value"), "ADNI structural MRI effects")
data.table::fwrite(mri, file.path(data_dir, "figure_mri_effects.csv"), na = "NA")

write_lines(c("Figure inputs exported from the frozen result tree.", "No participant-level data or images are copied by this script."), "12_figure_input_export_status.txt")
