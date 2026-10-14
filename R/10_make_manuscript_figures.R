source(file.path("R", "00_common.R"), encoding = "UTF-8")

if (!requireNamespace("ggplot2", quietly = TRUE) || !requireNamespace("patchwork", quietly = TRUE) || !requireNamespace("svglite", quietly = TRUE) || !requireNamespace("ragg", quietly = TRUE)) {
  stop("Install ggplot2, patchwork, svglite and ragg before generating figures.", call. = FALSE)
}

figure_dir <- file.path(output_dir, "figures")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
ggplot2::theme_set(ggplot2::theme_classic(base_size = 8, base_family = "Arial"))

save_pub <- function(plot, name, width_mm = 183, height_mm = 120) {
  w <- width_mm / 25.4
  h <- height_mm / 25.4
  svglite::svglite(file.path(figure_dir, paste0(name, ".svg")), width = w, height = h)
  print(plot)
  grDevices::dev.off()
  grDevices::cairo_pdf(file.path(figure_dir, paste0(name, ".pdf")), width = w, height = h, family = "Arial")
  print(plot)
  grDevices::dev.off()
  ragg::agg_tiff(file.path(figure_dir, paste0(name, ".tiff")), width = w, height = h, units = "in", res = 600)
  print(plot)
  grDevices::dev.off()
}

read_template <- function(name, required) {
  x <- data.table::fread(need_file(name), showProgress = FALSE)
  need_columns(x, required, name)
  x
}

traj <- read_template("figure_trajectories.csv", c("model", "time_years", "estimate", "conf_low", "conf_high", "group"))
p_traj <- ggplot2::ggplot(traj, ggplot2::aes(time_years, estimate, colour = group, fill = group)) +
  ggplot2::geom_ribbon(ggplot2::aes(ymin = conf_low, ymax = conf_high), alpha = 0.16, colour = NA) +
  ggplot2::geom_line(linewidth = 0.55) + ggplot2::geom_point(size = 1.2) +
  ggplot2::facet_wrap(~ model, scales = "free_y") +
  ggplot2::labs(x = "Years from baseline", y = "Standardised structural estimate", colour = NULL, fill = NULL) +
  ggplot2::theme(legend.position = "top", panel.grid = ggplot2::element_blank())
save_pub(p_traj, "Figure_1_ADNI_predicted_trajectories", 183, 105)

mri <- read_template("figure_mri_effects.csv", c("outcome", "exposure", "estimate", "conf_low", "conf_high", "p_value", "measure"))
mri[, label := paste(outcome, exposure, sep = " | ")]
p_mri <- ggplot2::ggplot(mri, ggplot2::aes(estimate, reorder(label, estimate), colour = measure)) +
  ggplot2::geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  ggplot2::geom_errorbar(ggplot2::aes(xmin = conf_low, xmax = conf_high), orientation = "y", width = 0.16) +
  ggplot2::geom_point(size = 1.7) + ggplot2::labs(x = "Adjusted estimate (95% CI)", y = NULL, colour = "Measure") +
  ggplot2::theme_classic(base_size = 7) + ggplot2::theme(legend.position = "top")
save_pub(p_mri, "Figure_2_ADNI_structural_effects", 183, 125)

qc <- read_template("figure_cat12_qc.csv", c("participant_id", "report_path", "roi_path", "iqr", "gm_tiv_ratio", "quality_flag"))
p_qc <- ggplot2::ggplot(qc, ggplot2::aes(gm_tiv_ratio, iqr, colour = quality_flag)) +
  ggplot2::geom_point(size = 1.3, alpha = 0.75) +
  ggplot2::labs(x = "Temporal GM / TIV ratio", y = "CAT12 image quality rating", colour = "QC flag") +
  ggplot2::theme(legend.position = "top")
save_pub(p_qc, "Figure_3_CAT12_quality_control", 92, 82)

write_lines(capture.output(summary(qc)), "figure_3_cat12_qc_summary.txt")

if (requireNamespace("RNifti", quietly = TRUE)) {
  manifest <- read_template("figure_cat12_image_manifest.csv", c("participant_id", "t1_path", "gm_path", "quality_score", "include"))
  manifest <- manifest[include %in% c(TRUE, 1, "1", "TRUE", "true") & file.exists(t1_path)]
  if (nrow(manifest) > 0L) {
    make_slice <- function(path, label) {
      img <- drop(RNifti::readNifti(path))
      if (length(dim(img)) != 3L) stop("T1 image must be three-dimensional: ", path, call. = FALSE)
      z <- dim(img)[3]
      idx <- unique(round(seq(max(2, z * 0.35), min(z - 1, z * 0.65), length.out = 3)))
      dat <- data.table::rbindlist(lapply(idx, function(k) {
        m <- img[, , k]
        q <- stats::quantile(m[is.finite(m)], c(0.01, 0.99), na.rm = TRUE)
        m <- pmin(pmax(m, q[1]), q[2])
        data.table::as.data.table(as.table(m))[, `:=`(slice = k, panel = label)]
      }))
      data.table::setnames(dat, c("Var1", "Var2", "N"), c("x", "y", "value"), skip_absent = TRUE)
      dat[, `:=`(x = as.integer(x), y = as.integer(y), value = as.numeric(value))]
      dat
    }
    n_show <- min(16L, nrow(manifest))
    slices <- data.table::rbindlist(lapply(seq_len(n_show), function(i) make_slice(manifest$t1_path[i], manifest$participant_id[i])), fill = TRUE)
    p_img <- ggplot2::ggplot(slices, ggplot2::aes(x, y, fill = value)) +
      ggplot2::geom_raster() + ggplot2::scale_fill_gray(guide = "none") +
      ggplot2::coord_equal() + ggplot2::facet_wrap(~ panel, ncol = 4) +
      ggplot2::theme_void() + ggplot2::labs(title = "Baseline T1 MRI montage")
    save_pub(p_img, "Figure_4_AIBL_T1_MRI_montage", 183, 150)
  }
} else {
  write_lines("RNifti is unavailable; no T1 montage was rendered.", "figure_4_T1_montage_status.txt")
}

aibl_model_path <- file.path(data_dir, "figure_aibl_models.csv")
if (file.exists(aibl_model_path)) {
  aa <- data.table::fread(aibl_model_path, showProgress = FALSE)
  ext <- aa[term %in% c("cat12_score_ADNI_frozen", "cat12_vulnerability_z")][1, .(term = "AIBL CAT12 vulnerability", hazard_ratio, conf_low, conf_high)]
} else {
  aibl <- read_template("aibl_cat12_incident_ad.csv", c("participant_id", "cat12_vulnerability_z", "followup_years", "incident_ad", "baseline_cn_mci", "age", "sex", "baseline_mmse", "APOE4"))
  aibl <- aibl[baseline_cn_mci == 1]
  fit <- survival::coxph(survival::Surv(followup_years, incident_ad) ~ cat12_vulnerability_z + age + sex + baseline_mmse + APOE4, data = aibl)
  sm <- summary(fit)$conf.int
  ext <- if ("cat12_vulnerability_z" %in% rownames(sm)) data.table::data.table(term = "AIBL CAT12 vulnerability", hazard_ratio = sm["cat12_vulnerability_z", "exp(coef)"], conf_low = sm["cat12_vulnerability_z", "lower .95"], conf_high = sm["cat12_vulnerability_z", "upper .95"]) else data.table::data.table()
}
if (nrow(ext) > 0L) {
  p_ext <- ggplot2::ggplot(ext, ggplot2::aes(hazard_ratio, term)) + ggplot2::geom_vline(xintercept = 1, linetype = 2) + ggplot2::geom_errorbar(ggplot2::aes(xmin = conf_low, xmax = conf_high), width = 0.15, orientation = "y") + ggplot2::geom_point(size = 2) + ggplot2::scale_x_log10() + ggplot2::labs(x = "Hazard ratio (log scale)", y = NULL)
  save_pub(p_ext, "Figure_5_AIBL_incident_AD_forest", 120, 70)
}

write_lines(capture.output(sessionInfo()), "figure_sessionInfo.txt")
