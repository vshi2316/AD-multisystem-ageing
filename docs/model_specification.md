# Model specification

## Population layer

The four harmonised domain scores are retained on their prespecified 0-1 scales and combined only when all four domains are observed:

`MAV_i = mean(cardiometabolic_i, sleep_i, sensory_i, physical_i)`.

Domain vulnerability thresholds are fixed at 0.40 for cardiometabolic risk, 0.50 for sleep risk, 0.60 for sensory risk, and mobility score >=2 on the original 0-7 scale, represented in the template as physical risk >=2/7. Multisystem vulnerability is present when at least two domain thresholds are met.

The five cohorts retain their own sampling and endpoint context. The primary event model is a Cox model for first-detected dementia with age, sex and cohort-stratified baseline hazard.

## Genomic layer

`gMAV_i = sum_k w_MAV,k G_i,k`

`gAD-noAPOE_i = gAD_raw_i - gamma_APOE APOE4_i`

Genomic structural equation models use `X = Lambda F + epsilon` and `Sigma = Lambda Phi Lambda' + Theta` when covariance and factor-mapping inputs are supplied. Score correlation remains a score-level quantity. LDSC genetic correlation is reported when LDSC fields are supplied.

## ADNI structural-clinical bridge

The longitudinal model is

`ad_vulnerable_gm ~ time*gAD-noAPOE + time*gMAV + age + sex + education + diagnosis + scanner + (1 + time | participant)`.

The primary contrast is the within-model difference between the `time*gAD-noAPOE` and `time*gMAV` coefficients. Clinical Cox models use baseline CN/MCI participants and evaluate the structural term as an increment to the clinical model.

## AIBL external structural test

AIBL uses baseline CN/MCI participants only. Participants with prevalent baseline AD are excluded. The endpoint is first post-baseline AD conversion. CAT12 temporal grey-matter/TIV-normalised values are analysed separately from the ADNI FreeSurfer-derived structural phenotype.

## Evidence roles

Population cohorts establish transportability of multisystem vulnerability. ADNI provides deep phenotyping and the clinical bridge. HABS-HD supplies biological concordance. AIBL supplies an independently processed raw-T1 incident-AD test.
