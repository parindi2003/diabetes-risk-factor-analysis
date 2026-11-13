# Diabetes Risk Factor Analysis and Predictive Modelling

**IT3081 – Statistical Modelling | Group Assignment**  
**Group:** DS-WE-02-G42  
**Dataset:** Behavioral Risk Factor Surveillance System (BRFSS), 2015  
**Project type:** Collaborative academic project

## Project Overview

This project investigates health and lifestyle indicators associated with diabetes status using the 2015 BRFSS health-indicator dataset. It applies descriptive statistics, statistical inference and predictive statistical modelling in R, then evaluates multivariate and Bayesian approaches to support evidence-informed healthcare decision-making.

The work was completed as a group assignment. My estimated individual contribution was approximately **75% of the overall project work**; the specific areas I contributed to are listed in [CONTRIBUTIONS.md](CONTRIBUTIONS.md).

> **Scope note:** This repository contains the R analysis workflow and supporting project documentation. It is not a substitute for the full consultancy report, presentation or viva deliverables required by the university assignment.

## Problem Context

Diabetes creates a significant public-health and healthcare-planning challenge. Understanding how demographic, behavioural and health-related indicators relate to diabetes status can help healthcare stakeholders identify patterns, prioritize prevention initiatives and explore risk-screening approaches.

The analysis uses BRFSS 2015 survey indicators. It is observational and cross-sectional; results should be interpreted as associations and model-based estimates, not causal effects or clinical diagnoses.

## Project Objectives

- Understand the dataset, its variables and data-quality characteristics.
- Describe diabetes status and relevant demographic, behavioural and health indicators.
- Apply appropriate statistical tests and interpret effect sizes alongside statistical significance.
- Develop and compare predictive classification models.
- Evaluate model assumptions and predictive performance.
- Assess the usefulness and limitations of PCA and Bayesian methods for this problem.
- Translate statistical analysis into considerations for healthcare decision-making.

## Dataset

The R script expects the following file:

```text
data/diabetes_012_health_indicators_BRFSS2015.csv
```

The dataset file is **not included** in this repository. Please obtain it from the same public source used by the project team and review `data/README.md` for placement and citation instructions. The uploaded assignment brief requires datasets to be publicly accessible and properly referenced. The exact download URL/version used by the group was not included in the supplied R script or assignment PDF, so it should be added before publishing this repository.

The script works with the `Diabetes_012` outcome and 21 predictor variables. For the main binary classification workflow, it recodes the outcome as:

- `No`: no diabetes (`Diabetes_012 == 0`)
- `Yes`: pre-diabetes or diabetes (`Diabetes_012` equal to 1 or 2)

It also retains a three-class outcome (`None`, `Prediabetes`, `Diabetes`) for an additional multinomial modelling extension. Review this outcome grouping carefully when interpreting results.

## Methods and Assignment Coverage

The supplied R script implements the following analytical components:

| Assignment task | Coverage in this repository | Main methods / content |
|---|---|---|
| Task 3 – Dataset understanding and descriptive analysis | Implemented in R | Variable dictionary, missing-value checks, range checks, duplicate assessment, descriptive statistics, prevalence summaries and visualizations |
| Task 4 – Statistical inference | Implemented in R | Welch t-tests, Wilcoxon rank-sum test, variance tests, Levene's test, ANOVA, Welch ANOVA, Kruskal–Wallis, proportion test, chi-square tests and effect sizes |
| Task 5 – Predictive statistical modelling | Implemented in R | Logistic regression, LASSO, Ridge, Elastic Net, stepwise selection, cross-validation, ROC/AUC, threshold selection, calibration and classification metrics |
| Task 7 – PCA evaluation | Implemented in R | PCA on selected continuous/ordinal variables and all predictors; principal-component regression comparison |
| Task 8 – Bayesian methods | Implemented in R | Naïve Bayes, Bayesian logistic regression / posterior simulation and Bayesian decision analysis; optional Stan workflow is disabled by default |
| Task 9 – Time series | Optional simulated illustration only | The script demonstrates a simulated ARIMA workflow. This is not real BRFSS time-series evidence. The assignment asks for a critical discussion, not an actual time-series analysis. |
| Tasks 1, 2, 6, 10, 11 and 12 | Not evidenced by the R script | These require written industry context, literature review, experimental-design discussion, innovation proposal, expert validation and final recommendations in the separate consultancy deliverables. |

The assignment brief requires a literature review of at least 15 peer-reviewed papers, including at least 10 journal papers and at least 5 papers from the last five years. It also requires at least one relevant industry expert consultation. Those requirements cannot be demonstrated by the R script alone.

## Key Analytical Design Decisions

The script documents several decisions that should be understood and defended during the viva:

1. Duplicate rows are retained in the primary analysis, with a duplicate-removed sensitivity analysis included.
2. The primary binary outcome combines pre-diabetes and diabetes into one positive class.
3. The train/test split is stratified (70/30) with a fixed seed.
4. The classification threshold is selected using training data rather than the test set.
5. `GenHlth` is represented as an unordered factor in the regression models, while `Age`, `Education` and `Income` are treated as numeric scores.

These are analytical choices, not universal rules; their suitability and limitations should be explained in the report.

## Tools and R Packages

- R
- `car`
- `corrplot`
- `pROC`
- `glmnet`
- `e1071`
- `arm`
- `factoextra`
- `forecast`

The script checks for the listed packages and installs missing ones when run. The optional Stan model requires `rstanarm`, which is not enabled by default.

## Repository Structure

```text
diabetes-risk-factor-analysis/
├── README.md
├── CONTRIBUTIONS.md
├── diabetes_risk_analysis.R
├── .gitignore
├── data/
│   └── README.md
└── results/
    ├── figures/          # Place selected, reviewed figures here
    └── tables/           # Place selected, reviewed tables here
```

Generated analysis files are written to `results/diabetes_outputs/` when the script runs. Generated outputs and the source dataset are excluded from Git by default; selectively add small, useful and reviewed figures/tables if you want to showcase them.

## How to Run

1. Install [R](https://www.r-project.org/) (RStudio is optional but recommended).
2. Obtain the dataset and place the CSV at the path shown in the Dataset section.
3. Clone or download this repository.
4. Open the project folder as the working directory in RStudio, or navigate to the folder in a terminal.
5. Run the script:

```r
source("diabetes_risk_analysis.R")
```

Alternatively, from a terminal:

```bash
Rscript diabetes_risk_analysis.R
```

The script stops with a clear error if the dataset is not found. The stepwise-selection section may take additional time. To skip it, change `RUN_STEPWISE <- TRUE` to `FALSE` near the top of the script. The optional Stan model is disabled by default (`RUN_STAN <- FALSE`).

## Outputs

The script saves figures, CSV tables and session information under `results/diabetes_outputs/`. Output names include descriptive-analysis figures, statistical-test tables, model-comparison tables, PCA plots, Bayesian decision plots and simulated time-series illustrations.

No numerical performance results are hard-coded in this README. Run the analysis and report the values actually produced by the current dataset and software environment. Do not describe the simulated time-series output as an observed healthcare trend.

## Limitations and Responsible Interpretation

- BRFSS 2015 is cross-sectional survey data; it does not establish temporal order or causality.
- The binary target combines pre-diabetes and diabetes, which simplifies the classification task and loses the distinction between those groups.
- Survey-derived indicators and self-reported measures may contain reporting and measurement limitations.
- Class imbalance makes accuracy alone an insufficient performance measure; sensitivity, specificity, precision, F1, balanced accuracy and AUC should be considered together.
- A predictive model trained on this dataset is an analytical research exercise, not a clinically validated diagnostic tool.
- The simulated Task 9 workflow is illustrative only. Real forecasting would require genuine repeated observations over time.
- The assignment's literature review, expert validation, innovation proposal and management recommendations must be supported by the group's separate evidence and report.

## Academic Integrity and Acknowledgements

This is a collaborative university assignment. Dataset providers, research papers, software packages and any tools used in preparing the project should be acknowledged in the final academic submission and in this repository where applicable. Add the exact dataset citation and the group's research references before making the repository public. Any use of generative AI should be disclosed in accordance with the university's academic-integrity guidance.

## Author / Contribution

See [CONTRIBUTIONS.md](CONTRIBUTIONS.md) for a transparent summary of the individual work claimed within this group project. The approximate contribution percentage is self-reported and should be retained only if it accurately reflects the group's agreed contribution record.
