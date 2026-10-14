# Code inventory and publication boundary

The public repository contains the manuscript-facing analysis layer. The private production tree also includes data acquisition, image processing and result-freezing components that reference restricted files or local software.

## Publicly included

| Public path | Role |
| --- | --- |
| `R/00_common.R` and `R/00_validate_inputs.R` | Shared paths, schema checks and input validation |
| `R/01_population_MAV.R` and `R/01_population_event_study.R` | Harmonised population scores and event-aligned trajectories |
| `R/02_genomic_equations.R` and `R/08_genomic_LDSC_boundary.R` | Genomic score, covariance and LDSC boundary handling |
| `R/03_*` | ADNI longitudinal and A/T/N models |
| `R/04_*` and `R/05_ADNI_5y_performance.R` | Structural-clinical bridge and performance analysis |
| `R/06_HABS_HD_concordance.R` and `R/07_AIBL_CAT12_incident_AD.R` | Biological concordance and incident-AD bridge |
| `R/09_session_info.R` | Software-environment record |
| `R/10_make_manuscript_figures.R` | Manuscript-facing statistical figures and optional T1 montage |
| `R/12_export_figure_inputs_from_frozen_results.R` | Frozen-result to figure-input export |
| `R/11_S7_covariance_aware_sensitivity_contrasts.R` | Covariance-aware direct slope contrasts and frozen-result audits |
| `docs/` and `tests/` | Input specifications, model definitions and lightweight checks |

## Kept outside the public repository

The private production tree contains data inventory and freeze scripts, source-file locators, cohort linkage audits, HRS, ELSA and SHARE mortality or competing-risk analyses, GWAS and Genomic SEM preparation, ADNI PGS assembly, CAT12 and DICOM processing, image quality-control wrappers, manuscript-figure source scripts, result-freezing scripts and Windows batch launchers. These components depend on restricted files or local software and remain in the controlled analysis environment.

Their absence from this repository describes the publication boundary. The public code exposes the reusable analysis layer and the frozen-result interfaces. The source-data processing layer stays local.

## Reproducibility status

The public-table workflow runs after authorized derived tables are supplied through `AD_MAV_DATA_DIR`. The frozen-result workflow runs after the required result directories are supplied through `AD_MAV_FROZEN_RESULTS_ROOT`.

The S7 script checks six model specifications against frozen component estimates and the primary direct contrast. A successful run writes `03_success_marker.txt`. The marker provides the completion criterion for this analysis step.
