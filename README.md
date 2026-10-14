# mav-ad-risk

Public R code for the multisystem vulnerability, genomic risk and Alzheimer disease progression study.

This repository provides analysis scripts, input specifications, figure generation and a path-configurable implementation of the covariance-aware S7 sensitivity contrasts. Participant-level data, raw MRI or DICOM files, genotype files, CAT12 installers, private processing logs and generated result trees are stored separately.

## Repository status

The private production tree retains source-data audits, cohort linkage repairs, CAT12 execution wrappers, private quality-control scripts and result-freezing scripts that reference restricted data or local software. `docs/code_inventory.md` records the public code boundary. Numerical results require authorized derived tables or a local frozen result tree.

## Repository layout

```
.
├── R/                   # analysis modules and figure generation
├── docs/                # data dictionary, model specification and code inventory
├── scripts/             # analysis and figure entry points
├── tests/               # repository checks
├── DESCRIPTION         # R dependency metadata
└── README.md
```

## Analysis scope

1. Harmonise the four prespecified non-cognitive multisystem vulnerability domains across the population cohorts.
2. Derive the prespecified gMAV and gAD-noAPOE scores and preserve the boundary between score transfer and linkage-disequilibrium score regression.
3. Fit the ADNI longitudinal structural model and estimate the within-model difference between the `time_years:gAD` and `time_years:gMAV` coefficients.
4. Link the structural phenotype with ADNI pathology, cognition and first-detected dementia outcomes.
5. Evaluate HABS-HD biological concordance and the corrected AIBL incident-AD risk set.
6. Export frozen figure inputs and calculate covariance-aware direct slope contrasts across the primary and prespecified sensitivity models.

## Requirements

Use R >= 4.4. Install the packages required by the scripts you plan to run.

```r
install.packages(c(
  "data.table", "survival", "lme4", "lavaan", "pROC", "testthat",
  "ggplot2", "patchwork", "svglite", "ragg", "RNifti"
))
```

## Public-table workflow

Run from the repository root after setting `AD_MAV_DATA_DIR` to an external directory containing authorized derived tables. Required columns are documented in `docs/data_dictionary.md`.

```r
Sys.setenv(AD_MAV_REPO_ROOT = getwd())
Sys.setenv(AD_MAV_OUTPUT_DIR = file.path(getwd(), "results"))
Sys.setenv(AD_MAV_BOOTSTRAP_B = "500")
source("R/run_all.R", encoding = "UTF-8")
```

The same entry point is available through `scripts/run_analysis.R`. The pipeline stops during input validation when a required table or column is absent.

## Frozen-result workflow

`R/11_S7_covariance_aware_sensitivity_contrasts.R` and `R/12_export_figure_inputs_from_frozen_results.R` operate on a local frozen result tree. Set `AD_MAV_FROZEN_RESULTS_ROOT` to the directory containing folders such as `13K_core_claim_completion` and `13F_R1_final_analysis`. The figure-input exporter also writes to the external `AD_MAV_DATA_DIR`.

```r
Sys.setenv(AD_MAV_FROZEN_RESULTS_ROOT = file.path(getwd(), "results"))
Sys.setenv(AD_MAV_OUTPUT_DIR = "results")
source("R/11_S7_covariance_aware_sensitivity_contrasts.R", encoding = "UTF-8")
```

The S7 script reads the ADNI structural frame, longitudinal PGS table, automated raw-T1 flags, frozen component estimates, model diagnostics and the frozen primary direct contrast. It writes `01_S7_direct_slope_sensitivity_contrasts.csv`, `00_reproduction_audit.csv`, `02_sessionInfo.txt` and `03_success_marker.txt` under `13L_S7_covariance_aware_sensitivity_contrasts/` in `AD_MAV_OUTPUT_DIR`. The script verifies participant counts, MRI-row counts, random-effects structure, component estimates, component standard errors and the primary direct contrast before writing the success marker.

The S7 output supports an estimand-level direct slope comparison with covariance-aware uncertainty. Its evidence role is structural and comparative, with clinical utility and causal mediation outside the estimand defined here.

## Figures

After figure input tables are available in the external `AD_MAV_DATA_DIR`, run:

```r
Sys.setenv(AD_MAV_REPO_ROOT = getwd())
Sys.setenv(AD_MAV_OUTPUT_DIR = file.path(getwd(), "results"))
source("scripts/run_figures.R", encoding = "UTF-8")
```

The figure module writes PDF, SVG and 600-dpi TIFF files. The T1 montage requires valid local NIfTI paths in `figure_cat12_image_manifest.csv`; image files remain outside the repository. `R/12_export_figure_inputs_from_frozen_results.R` can create standardized plotting tables from a supplied frozen result tree before figure generation.

## Script map

`R/00_validate_inputs.R` checks schemas. `R/01_population_MAV.R` and `R/01_population_event_study.R` analyse the population layer. `R/02_genomic_equations.R` records genomic-score equations and optional Genomic SEM inputs. `R/03_*` covers ADNI longitudinal and A/T/N models. `R/04_*` covers clinical bridging and structural-pathology associations. `R/05_ADNI_5y_performance.R` calculates discrimination, Brier score and calibration. `R/06_HABS_HD_concordance.R` and `R/07_AIBL_CAT12_incident_AD.R` provide the external evidence layers. `R/08_genomic_LDSC_boundary.R` records the score-level and LDSC boundary. `R/09_session_info.R` records the software environment. `R/10_make_manuscript_figures.R` creates the public figure set. `R/11_S7_covariance_aware_sensitivity_contrasts.R` performs the covariance-aware S7 contrasts. `R/12_export_figure_inputs_from_frozen_results.R` exports frozen plotting tables.

## Validation

Run the repository tests and parse every public R script before upload:

```powershell
Rscript tests/testthat.R
Rscript -e "files <- list.files('R', pattern = '\\.R$', full.names = TRUE); invisible(lapply(files, parse)); cat('R_PARSE_OK\\n')"
```

The public repository excludes `data/`, `results/` and local history files through `.gitignore`. Review the staged file list before publishing and confirm that it contains code, documentation and tests only.

## Interpretation boundary

The primary scientific contribution is a genetically differentiated AD-vulnerable structural trajectory connected to clinical and biological evidence. The public code preserves the distinction between structural association, external concordance, direct slope contrast and clinical prediction performance. The current external performance analysis remains at the evaluation stage, with no validated clinical prediction claim.
