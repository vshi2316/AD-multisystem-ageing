# Data dictionary

All participant-level tables are de-identified. Times are years from the cohort-specific baseline. Missing values use `NA`.

Set `AD_MAV_DATA_DIR` to an external directory containing authorized derived tables with the columns below. Cohort data, raw images, genotype files and frozen numerical results remain outside the repository.

## Population tables

`population_long.csv`: `participant_id`, `cohort`, `age`, `sex`, `followup_years`, `dementia_event`, `cognitive_z`, `mav_onset_year`, `mav_cardiometabolic`, `mav_sleep`, `mav_sensory`, `mav_physical`.

`population_event_long.csv`: `participant_id`, `cohort`, `visit_year`, `cognitive_z`, `mav_onset_year`, `age_baseline`, `sex`, `education`, `event_route`.

The four MAV domain values use the frozen 0-1 scales. `mav_physical` is the mobility risk expressed as the original 0-7 mobility score divided by 7.

## Genomic tables

`genomic_scores.csv`: `participant_id`, `gMAV`, `gAD_noAPOE`, `APOE4`; ancestry principal components may be appended.

`genomic_summary.csv`: `trait`, `estimate`, `standard_error`, `p_value`; optional LDSC fields are `genetic_correlation`, `genetic_correlation_se`, and `ldsc_model`.

`genomic_sem_mapping.csv`: optional `trait`, `factor` mapping for the supplied covariance matrix.

`genomic_covariance.csv`: optional wide covariance matrix with a `trait` column and one column per mapped trait.

## ADNI tables

`adni_longitudinal.csv`: `participant_id`, `time_years`, `ad_vulnerable_gm`, `gMAV`, `gAD_noAPOE`, `age`, `sex`, `education`, `diagnosis`, `scanner`.

`adni_atvn.csv`: `participant_id`, `time_years`, `clinical_outcome`, `gMAV`, `gAD_noAPOE`, `APOE4`, `amyloid`, `tau`, `neurodegeneration`, `age`, `sex`, `education`.

`adni_clinical.csv`: `participant_id`, `followup_years`, `dementia_event`, `baseline_cn_mci`, `age`, `sex`, `education`, `baseline_mmse`, `APOE4`.

`adni_mri_pathology.csv`: structural MRI indices, amyloid/tau markers, PGS variables, demographic covariates and `scanner`.

`adni_cat12_bridge.csv`: `participant_id`, `cat12_vulnerability_z`, `gAD_noAPOE`, `gMAV`, `followup_years`, `dementia_event`. This table contains the CAT12-derived structural endpoint after the frozen image-processing workflow.

## HABS-HD and AIBL tables

`habs_hd.csv`: `participant_id`, `gAD_noAPOE`, `ad_vulnerable_gm`, `memory_score`, `age`, `sex`.

`aibl_cat12_incident_ad.csv`: `participant_id`, `cat12_vulnerability_z`, `followup_years`, `incident_ad`, `baseline_cn_mci`, `age`, `sex`, `baseline_mmse`, `APOE4`.

## Figure tables

`figure_trajectories.csv` contains `model`, `time_years`, `estimate`, `conf_low`, `conf_high`, and `group` for predicted trajectory panels.

`figure_mri_effects.csv` contains the frozen ADNI structural outcome, genetic exposure, estimate, confidence limits, `p_value`, and `measure` fields used for the structural effect forest plot.

`figure_cat12_qc.csv` contains `participant_id`, `report_path`, `roi_path`, `iqr`, `gm_tiv_ratio`, and `quality_flag`.

`figure_cat12_image_manifest.csv` contains `participant_id`, local `t1_path`, optional `gm_path`, `quality_score`, and `include` for the blinded T1 montage. The image files stay outside the repository.

## Frozen-result inputs for S7

`R/11_S7_covariance_aware_sensitivity_contrasts.R` reads a local frozen result tree specified by `AD_MAV_FROZEN_RESULTS_ROOT`. It requires the following files:

* `13F_R_only_structural_analysis/04_ADNI_R_only_longitudinal_structural_frame.rds`
* `10A_ADNI_gMAV_PGS_assembly/02_ADNI_gMAV_gAD_PGS_longitudinal_clinical.tsv`
* `13F_automated_raw_T1_QC_and_processing_manifest/04_automatic_QC_flagged_images.csv`
* `13F_final_revised_results/01_ADNI_primary_and_sensitivity_key_terms.csv`
* `13F_R1_final_analysis/01_model_coefficients.csv`
* `13F_R1_final_analysis/02_model_diagnostics.csv`
* `13K_core_claim_completion/01_gAD_vs_gMAV_direct_slope_contrast.csv`

These files are local interfaces to frozen results. The script writes covariance-aware direct slope contrasts and a component-level reproduction audit to the configured output directory.
