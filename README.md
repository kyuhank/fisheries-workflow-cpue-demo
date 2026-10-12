# Fisheries workflow: CPUE

This repository owns 8 of the 22 demonstration jobs: submission, quality check,
database preparation, extraction, two CPUE analyses, comparison and reporting.
The coordinator loads an exact commit and preserves the source bytes used.

The public example uses WCPFC longline catch and effort records for the reported
FJ fleet. Each record combines a year, five-degree cell and quarter. Vessel
identifiers are unavailable; the legacy `set_id` field identifies an aggregate
source row. The prepared profile covers six strata in 2000–2022: the initial
snapshot ends in 2021, and the update adds 2022.

[R/cpue.R](R/cpue.R) contains the calculations. Analysis A fits a quasipoisson
GLM with year and cell–quarter effects; B fits year effects only. Both use a log
link and `log(hooks / 1000)` as an effort offset. Predictions at 1000 hooks are
averaged over the same strata with equal weights in every year, then divided by
the first-year prediction. Outputs preserve nominal CPUE, standardised CPUE,
the prediction grid, weights and model checks. Released zeros are retained when
supplied. An effort filter fails if it removes an entire year or stratum.

Run [CPUE A](jobs/cpue_a/run.R) and [CPUE B](jobs/cpue_b/run.R) through the
coordinator in the declared container. These aggregate indices describe the selected fleet and
released strata. The example supplies no confidence intervals or official stock
assessment advice.

The code originated in `kyuhank/fisheries-workflow-demo` commit
`b6dc067d5346d3809edf0ad66a0f6c7e7d07ce93`; this version adds the public-data
method and retains the synthetic year/vessel Poisson example.
[SOURCE.json](SOURCE.json) records that origin and the current library checksum.
