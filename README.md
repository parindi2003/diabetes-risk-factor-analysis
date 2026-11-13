# Diabetes Risk Factor Analysis and Predictive Modelling

**IT3081 – Statistical Modelling | Group Assignment**
**Group:** DS-WE-02-G42
**Dataset:** Behavioral Risk Factor Surveillance System (BRFSS), 2015

## Project Overview

This project investigates health and lifestyle indicators associated with diabetes status using the 2015 BRFSS health-indicator dataset. It applies descriptive statistics, statistical inference and predictive modelling in R, and evaluates PCA, Bayesian methods and experimental-design concepts to support evidence-informed healthcare decision-making.

This was a group assignment. I was responsible for the R analysis workflow in this repository, including data cleaning, statistical inference, predictive modelling, PCA, Bayesian methods and the risk-score prototype. See [CONTRIBUTIONS.md](CONTRIBUTIONS.md) for details.

> **Scope note:** This repository contains the R analysis workflow and supporting documentation. It is not a substitute for the full consultancy report, presentation or viva deliverables required by the assignment.

## Problem Context

Diabetes is a major public-health and healthcare-planning challenge. Understanding how demographic, behavioural and health indicators relate to diabetes status can help stakeholders identify patterns, prioritise prevention and explore risk-screening approaches.

The data are observational and cross-sectional. Results should be read as associations and model-based estimates, **not** causal effects or clinical diagnoses.

## Project Objectives

- Understand the dataset, its variables and data-quality characteristics.
- Describe diabetes status and key demographic, behavioural and health indicators.
- Apply appropriate statistical tests and interpret effect sizes alongside p-values.
- Develop and compare predictive classification models.
- Evaluate model assumptions and predictive performance.
- Assess the usefulness and limitations of PCA and Bayesian methods.
- Prototype a risk-scoring framework and discuss its use in healthcare decision-making.

## Dataset

The script expects the file:

```
data/diabetes_012_health_indicators_BRFSS2015.csv
```

The CSV is **not included** in this repository because of its size. Download it from Kaggle (Diabetes Health Indicators Dataset)(https://www.kaggle.com/datasets/alexteboul/diabetes-health-indicators-dataset) and place it in the `data/` folder. See [data/README.md](data/README.md).

The dataset contains the outcome `Diabetes_012` (0 = no diabetes, 1 = prediabetes, 2 = diabetes) and 21 predictor variables.

- **Primary binary target:** `No` = no diabetes; `Yes` = prediabetes or diabetes (early-detection objective).
- **Strict target (sensitivity analysis):** `Yes` = diabetes only.
- A three-level status variable is also kept for descriptive analysis.

## Methods and Assignment Coverage

| Task | Coverage | Main methods |
|------|----------|--------------|
| 3 – Dataset understanding and descriptive analysis | Implemented in R | Data dictionary, missing values, range checks, duplicate removal, class balance, IQR outlier detection, descriptive statistics, visualisations |
| 4 – Statistical inference | Implemented in R | Welch t-test, Wilcoxon rank-sum, F-test, Levene's test, one-way ANOVA with Tukey HSD, Welch ANOVA, Kruskal–Wallis, proportion tests with odds ratios (Bonferroni-adjusted), chi-square test |
| 5 – Predictive modelling | Implemented in R | Stratified 70/30 split, logistic regression, VIF, odds ratios with 95% CI, forward/backward stepwise selection, LASSO / Ridge / Elastic Net, ROC/AUC, Youden threshold, cross-validation, strict-target sensitivity analysis |
| 6 – Experimental design | Illustrative demos in R | CRD vs RCBD comparison, sample-size calculation, simulated trial power |
| 7 – PCA | Implemented in R | PCA on 7 numeric/ordinal variables, scree plot, biplot, Kaiser rule, PCA vs original-variable model comparison |
| 8 – Bayesian methods | Implemented in R | Naive Bayes, Bayesian logistic regression (`bayesglm`), Beta-Binomial posterior prevalence, cost-based decision threshold |
| 9 – Time series | Simulated illustration only | Decomposition and ARIMA workflow on **simulated** data. This is not real BRFSS time-series evidence. |
| 10 – Innovation prototype | Implemented in R | Early-warning risk score with Low / Moderate / High tiers |
| 1, 2, 11, 12 | Not covered by the script | Industry context, literature review, expert validation and final recommendations are in the separate consultancy deliverables. |

## Key Analytical Decisions

- Exact duplicate rows are **removed** (the count and percentage are reported first).
- Prediabetes and diabetes are combined into one positive class for the primary analysis; a diabetes-only target is used as a sensitivity check.
- The train/test split is stratified (70/30) with a fixed seed.
- The classification threshold is chosen on the **training** data, not the test set.
- `GenHlth` is an unordered factor in the regression models; `Age`, `Education` and `Income` are treated as numeric scores.
- High BMI values are extreme but plausible, so they are retained and robust tests are used alongside parametric ones.

## Tools and R Packages

R, `car`, `glmnet`, `pROC`, `e1071`, `corrplot`, `forecast`, `arm`

Missing packages are installed automatically on the first run.

## Repository Structure

```
.
├── diabetes_risk_analysis.R    # Main analysis script
├── README.md
├── CONTRIBUTIONS.md
├── .gitignore
├── data/
│   └── README.md               # Dataset download instructions
├── figures/                    # Generated plots (PNG)
├── tables/                     # Generated tables (CSV)
└── results/
```

## How to Run

1. Install R (RStudio recommended).
2. Clone or download this repository.
3. Download the dataset and place it at `data/diabetes_012_health_indicators_BRFSS2015.csv`.
4. In RStudio, set the working directory: *Session > Set Working Directory > To Source File Location*.
5. Run the **whole script** from top to bottom (`Ctrl + Alt + R`), or from a terminal:
   ```bash
   Rscript diabetes_risk_analysis.R
   ```

The stepwise-selection and cross-validation sections may take a few minutes.

## Outputs

| Output | Location |
|--------|----------|
| Figures (PNG) | `figures/` |
| Tables (CSV) | `tables/` |
| Cleaned dataset | `diabetes_cleaned.csv` (not tracked in Git) |

No performance numbers are hard-coded in this README. Run the script to obtain the values produced by your own environment.

## Limitations and Responsible Interpretation

- BRFSS 2015 is cross-sectional survey data: it shows association, **not causation**.
- Survey weights were not applied, which may affect independence assumptions.
- Self-reported indicators may contain reporting and measurement bias.
- The binary target merges prediabetes and diabetes, losing the distinction between them.
- Class imbalance makes accuracy alone misleading, so sensitivity, specificity and AUC are reported together.
- The model is an analytical exercise, **not** a clinically validated diagnostic tool.
- Task 6 and Task 9 use simulated data for illustration only.

## Academic Integrity and Acknowledgements

This project was completed as part of a university group assignment. Dataset: CDC BRFSS 2015. Any use of generative AI tools should be disclosed in line with the university's academic-integrity guidance.

## Author

Parindi Kodithuwakku  – [GitHub](https://github.com/parindi2003) | 

See [CONTRIBUTIONS.md](CONTRIBUTIONS.md) for the work I carried out in this project.
