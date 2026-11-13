#IT3081 - Statistical Modelling
#Group Assignment
#DS-WE-02-G42
# Diabetes Risk Factor Analysis (BRFSS 2015)
#
# HOW TO RUN: keep this script and the CSV in the SAME folder, then
# Session > Set Working Directory > To Source File Location, then Source / Ctrl+Alt+R.
# ALWAYS run the whole script top to bottom (later sections use earlier objects).
# Figures -> ./figures   Tables -> ./tables   (they also appear in the Plots pane)

###############################################################################
# . SETUP (packages, data path, helper functions)
###############################################################################
need <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}
for (p in c("car", "glmnet", "pROC", "e1071", "corrplot", "forecast", "arm")) need(p)

set.seed(123)
dir.create("figures", showWarnings = FALSE)
dir.create("tables",  showWarnings = FALSE)

# Data path: same folder as the script. (Or put your full path in DATA_FILE.)
DATA_FILE <- "data/diabetes_012_health_indicators_BRFSS2015.csv"
# DATA_FILE <- "D:/Y3S1/Statistical modeling/SM assignment/diabetes_012_health_indicators_BRFSS2015.csv"
if (!file.exists(DATA_FILE)) stop("CSV not found. Working directory is: ", getwd(),
                                  "\nSet it with Session > Set Working Directory > To Source File Location.")

# Helper: save a plot as PNG in ./figures AND show it in the RStudio Plots pane
save_fig <- function(name, expr, w = 900, h = 600) {
  e <- substitute(expr); env <- parent.frame()
  png(file.path("figures", name), width = w, height = h, res = 120)
  eval(e, env)
  invisible(dev.off())
  #if (interactive()) eval(e, env)          # draw again on screen
  invisible(NULL)
}

###############################################################################
# Task 03 - Dataset Understanding and Descriptive Analysis
###############################################################################
diabetes_data <- read.csv(DATA_FILE)

head(diabetes_data)
str(diabetes_data)
dim(diabetes_data)
summary(diabetes_data)

# ---- Variable description (data dictionary) ----
dictionary <- data.frame(
  Variable = names(diabetes_data),
  Description = c(
    "0 = no diabetes, 1 = prediabetes, 2 = diabetes (target)",
    "High blood pressure", "High cholesterol", "Cholesterol check in last 5 years",
    "Body Mass Index", "Smoked >= 100 cigarettes (lifetime)", "Ever had stroke",
    "Coronary heart disease / heart attack", "Physical activity in last 30 days",
    "Eats fruit daily", "Eats vegetables daily", "Heavy alcohol consumption",
    "Has healthcare coverage", "Could not see doctor due to cost",
    "General health (1 = excellent ... 5 = poor)", "Poor mental health days (0-30)",
    "Poor physical health days (0-30)", "Serious difficulty walking", "0 = female, 1 = male",
    "Age category (1 = 18-24 ... 13 = 80+)", "Education level (1-6)", "Income level (1-8)"))
print(dictionary)
write.csv(dictionary, "tables/data_dictionary.csv", row.names = FALSE)

# ---- Missing values ----
colSums(is.na(diabetes_data))
sum(is.na(diabetes_data))

# ---- Duplicates: BRFSS answers are categorical, so identical respondents occur
# legitimately; we report the count, then remove exact duplicates (conservative).
n_dup <- sum(duplicated(diabetes_data))
n_dup
round(100 * n_dup / nrow(diabetes_data), 1)       # % duplicated
diabetes_data <- diabetes_data[!duplicated(diabetes_data), ]
dim(diabetes_data)
sum(duplicated(diabetes_data))

# validity checks
range(diabetes_data$Age)          # should be 1-13
range(diabetes_data$BMI)
range(diabetes_data$GenHlth)      # should be 1-5

# ---- Target definitions ----
# Primary target: prediabetes OR diabetes = "Yes" (early-detection objective).
# Strict target (diabetes only) is used as a sensitivity analysis in Task 5.
diabetes_data$diabetes <- factor(ifelse(diabetes_data$Diabetes_012 == 0, "No", "Yes"), levels = c("No", "Yes"))
diabetes_data$diab_strict <- factor(ifelse(diabetes_data$Diabetes_012 == 2, "Yes", "No"), levels = c("No", "Yes"))
diabetes_data$Diabetes_Status <- factor(diabetes_data$Diabetes_012, levels = 0:2,
                                        labels = c("No Diabetes", "Prediabetes", "Diabetes"))

# ---- Factor conversion of binary / ordinal variables ----
bin_cols <- c("HighBP", "HighChol", "CholCheck", "Smoker", "Stroke", "HeartDiseaseorAttack",
              "PhysActivity", "Fruits", "Veggies", "HvyAlcoholConsump", "AnyHealthcare",
              "NoDocbcCost", "DiffWalk")
for (v in bin_cols) diabetes_data[[v]] <- factor(diabetes_data[[v]], levels = c(0, 1), labels = c("No", "Yes"))
diabetes_data$Sex <- factor(diabetes_data$Sex, levels = c(0, 1), labels = c("Female", "Male"))

# GenHlth: numeric copy for correlation/PCA; UNORDERED factor for models
# (ordered factors give polynomial contrasts .L/.Q that cannot be read as odds ratios)
diabetes_data$GenHlth_num <- diabetes_data$GenHlth
diabetes_data$GenHlth <- factor(diabetes_data$GenHlth, levels = 1:5,
                                labels = c("Excellent", "Very Good", "Good", "Fair", "Poor"))
str(diabetes_data)

# ---- Class balance ----
round(prop.table(table(diabetes_data$Diabetes_Status)) * 100, 2)
round(prop.table(table(diabetes_data$diabetes)) * 100, 2)
# INTERPRETATION: strong imbalance -> accuracy is misleading; Task 5 reports
# sensitivity/specificity/AUC and tunes the decision threshold.

# ---- Descriptive statistics ----
num_vars <- c("BMI", "MentHlth", "PhysHlth", "Age", "Education", "Income")
desc <- do.call(rbind, lapply(num_vars, function(v) {
  x <- diabetes_data[[v]]
  data.frame(Variable = v, Mean = mean(x), SD = sd(x), Median = median(x),
             Min = min(x), Max = max(x), Skewness = e1071::skewness(x))
}))
desc[, -1] <- round(desc[, -1], 2); print(desc)
write.csv(desc, "tables/descriptive_numeric.csv", row.names = FALSE)

bin_tbl <- data.frame(
  Variable = bin_cols,
  Pct_Yes = sapply(bin_cols, function(v) round(100 * mean(diabetes_data[[v]] == "Yes"), 1)),
  Diabetes_pct_if_Yes = sapply(bin_cols, function(v) round(100 * mean(diabetes_data$diabetes[diabetes_data[[v]] == "Yes"] == "Yes"), 1)),
  Diabetes_pct_if_No  = sapply(bin_cols, function(v) round(100 * mean(diabetes_data$diabetes[diabetes_data[[v]] == "No"]  == "Yes"), 1)))
print(bin_tbl, row.names = FALSE)
write.csv(bin_tbl, "tables/descriptive_binary.csv", row.names = FALSE)

table(diabetes_data$Sex)
prop.table(table(diabetes_data$HighBP))

aggregate(cbind(Age, BMI, MentHlth, PhysHlth, Income, Education) ~ diabetes,
          data = diabetes_data, FUN = function(x) round(mean(x), 2))

# ---- Outlier detection (IQR rule) ----
iqr_outliers <- function(x) {
  q <- quantile(x, c(.25, .75)); i <- diff(q)
  lo <- q[1] - 1.5 * i; hi <- q[2] + 1.5 * i
  c(lower = lo, upper = hi, n_outliers = sum(x < lo | x > hi), pct = round(100 * mean(x < lo | x > hi), 2))
}
out_tbl <- t(sapply(c("BMI", "MentHlth", "PhysHlth"), function(v) iqr_outliers(diabetes_data[[v]])))
print(out_tbl); write.csv(out_tbl, "tables/outliers.csv")
# INTERPRETATION: high BMI (up to 98) is extreme but plausible (severe obesity)
# and is the group of interest -> RETAINED. MentHlth/PhysHlth are zero-inflated
# with a spike at 30 (chronic illness), also genuine -> robust tests used in Task 4.

# ---- Visualizations (each figure once) ----
cols3 <- c("#4C9BE8", "#F2B84B", "#E8734C")
par(mar = c(4, 4, 3, 1))
save_fig("01_class_distribution.png", {
  b <- barplot(table(diabetes_data$Diabetes_Status), col = cols3, main = "Distribution of Diabetes Status",
               ylab = "Respondents", ylim = c(0, max(table(diabetes_data$Diabetes_Status)) * 1.15))
  text(b, table(diabetes_data$Diabetes_Status), format(table(diabetes_data$Diabetes_Status), big.mark = ","), pos = 3)
})
save_fig("02_bmi_hist.png", hist(diabetes_data$BMI, breaks = 50, col = "lightblue", main = "Distribution of BMI", xlab = "BMI"))
save_fig("03_age_hist.png", hist(diabetes_data$Age, breaks = 0:13, col = "lightgreen",
                                 main = "Distribution of Age Category", xlab = "Age code (1 = 18-24 ... 13 = 80+)"))
save_fig("04_bmi_boxplot.png", boxplot(BMI ~ Diabetes_Status, diabetes_data, col = cols3, main = "BMI by Diabetes Status", xlab = "", ylab = "BMI"))
save_fig("05_age_boxplot.png", boxplot(Age ~ diabetes, diabetes_data, col = c("skyblue", "salmon"), main = "Age Category by Diabetes", xlab = "Diabetes", ylab = "Age code"))
save_fig("06_physhlth_boxplot.png", boxplot(PhysHlth ~ diabetes, diabetes_data, col = c("skyblue", "salmon"), main = "Physical Health Days by Diabetes", xlab = "Diabetes", ylab = "Unhealthy days (30)"))
save_fig("07_menthlth_boxplot.png", boxplot(MentHlth ~ diabetes, diabetes_data, col = c("lightpink", "salmon"), main = "Mental Health Days by Diabetes", xlab = "Diabetes", ylab = "Unhealthy days (30)"))
save_fig("08_age_by_status.png", {
  tab <- prop.table(table(diabetes_data$Age, diabetes_data$Diabetes_Status), 1)
  barplot(t(tab), col = cols3, main = "Diabetes Status by Age Category", xlab = "Age code", ylab = "Proportion",
          legend.text = colnames(tab), args.legend = list(x = "bottomright", cex = .7))
})
save_fig("09_genhlth_by_status.png", {
  tab <- prop.table(table(diabetes_data$GenHlth, diabetes_data$Diabetes_Status), 1)
  barplot(t(tab), col = cols3, main = "Diabetes Status by General Health", ylab = "Proportion",
          legend.text = colnames(tab), args.legend = list(x = "topleft", cex = .7))
})
save_fig("10_prevalence_by_factor.png", {
  v <- c("HighBP", "HighChol", "PhysActivity", "Smoker", "HeartDiseaseorAttack", "DiffWalk")
  m <- rbind(Yes = bin_tbl$Diabetes_pct_if_Yes[match(v, bin_tbl$Variable)], No = bin_tbl$Diabetes_pct_if_No[match(v, bin_tbl$Variable)])
  par(mar = c(8, 4, 3, 1))
  barplot(m, beside = TRUE, names.arg = v, col = c("#E8734C", "#4C9BE8"), las = 2, cex.names = .7,
          ylab = "% with diabetes/prediabetes", main = "Prevalence by Risk Factor",
          legend.text = c("Factor present", "Factor absent"), args.legend = list(x = "topright", cex = .8))
  par(mar = c(4, 4, 3, 1))
})

numeric_vars <- diabetes_data[, c("Age", "BMI", "MentHlth", "PhysHlth", "Income", "Education", "GenHlth_num")]
round(cor(numeric_vars), 3)
save_fig("11_correlation.png", corrplot::corrplot(cor(numeric_vars), method = "color", addCoef.col = "black",
         tl.col = "black", tl.srt = 45, col = colorRampPalette(c("#E8734C", "white", "#4C9BE8"))(200),
         title = "Correlation Matrix", mar = c(0, 0, 2, 0)))

###############################################################################
## Task 4: Statistical Inference
## (state H0/H1, why the test, result, effect size, interpretation in the report)
###############################################################################
cohens_d <- function(x, g) {
  a <- x[g == levels(g)[1]]; b <- x[g == levels(g)[2]]
  sp <- sqrt(((length(a) - 1) * var(a) + (length(b) - 1) * var(b)) / (length(a) + length(b) - 2))
  (mean(b) - mean(a)) / sp
}

# Test 1: comparison of MEANS - BMI by diabetes status
# H0: mean BMI (No) = mean BMI (Yes); H1: they differ. Welch t-test: independent
# groups, unequal variances; huge n -> CLT covers BMI's right skew.
t.test(BMI ~ diabetes, data = diabetes_data)
cohens_d(diabetes_data$BMI, diabetes_data$diabetes)

# Test 2: comparison of MEANS - physically unhealthy days (zero-inflated/skewed)
# H0: equal means; plus Wilcoxon rank-sum as a non-parametric robustness check.
t.test(PhysHlth ~ diabetes, data = diabetes_data)
wilcox.test(PhysHlth ~ diabetes, data = diabetes_data)
aggregate(PhysHlth ~ diabetes, diabetes_data, median)

# Test 3: comparison of VARIANCES - BMI
# H0: equal variances. F-test is sensitive to non-normality -> confirm with Levene.
var.test(BMI ~ diabetes, data = diabetes_data)
leveneTest(BMI ~ diabetes, data = diabetes_data)

# Test 4: ANOVA - BMI across General Health categories
# H0: mean BMI equal in all 5 groups; H1: at least one differs
anova_result <- aov(BMI ~ GenHlth, data = diabetes_data)
summary(anova_result)
ss <- summary(anova_result)[[1]]
ss[1, "Sum Sq"] / sum(ss[, "Sum Sq"])               # eta-squared (effect size)

# Assumptions (Shapiro-Wilk always rejects at this n, so use a Q-Q plot instead)
set.seed(123)
res_s <- sample(resid(anova_result), 5000)
save_fig("12_anova_qq.png", { qqnorm(res_s); qqline(res_s) })
plot(anova_result, which = 1)                       # residuals vs fitted
leveneTest(BMI ~ GenHlth, data = diabetes_data)     # homogeneity
oneway.test(BMI ~ GenHlth, data = diabetes_data)    # Welch ANOVA
kruskal.test(BMI ~ GenHlth, data = diabetes_data)   # non-parametric check
TukeyHSD(anova_result)                              # post-hoc

# Test 5: comparison of PROPORTIONS - prevalence with vs without each risk factor
# H0: p(diabetes | factor) equal in both groups. Reports prevalence difference,
# odds ratio with CI, and a Bonferroni-adjusted p-value (multiple tests).
prop_compare <- function(var) {
  g <- diabetes_data[[var]] == "Yes"
  x <- c(sum(diabetes_data$diabetes[g] == "Yes"), sum(diabetes_data$diabetes[!g] == "Yes"))
  n <- c(sum(g), sum(!g))
  pt <- prop.test(x, n, correct = FALSE)
  OR <- (x[1] / (n[1] - x[1])) / (x[2] / (n[2] - x[2]))
  se <- sqrt(sum(1 / c(x, n - x)))
  data.frame(Factor = var, Prev_present = round(100 * x[1] / n[1], 1), Prev_absent = round(100 * x[2] / n[2], 1),
             Diff_pp = round(100 * (x[1] / n[1] - x[2] / n[2]), 1), OR = round(OR, 2),
             OR_lo = round(exp(log(OR) - 1.96 * se), 2), OR_hi = round(exp(log(OR) + 1.96 * se), 2),
             p_value = pt$p.value)
}
prop_tbl <- do.call(rbind, lapply(c("HighBP", "HighChol", "PhysActivity", "Smoker", "HeartDiseaseorAttack"), prop_compare))
prop_tbl$p_bonferroni <- pmin(1, prop_tbl$p_value * nrow(prop_tbl))
print(prop_tbl, row.names = FALSE)
write.csv(prop_tbl, "tables/proportion_tests.csv", row.names = FALSE)
# INTERPRETATION: OR > 1 = higher odds with the factor; OR < 1 (PhysActivity) =
# protective association. Cross-sectional data -> association, NOT causation.

# Test 6: Chi-square - High BP vs 3-class diabetes status
ct <- table(diabetes_data$HighBP, diabetes_data$Diabetes_Status); ct
cs <- chisq.test(ct); cs
sqrt(cs$statistic / (sum(ct) * (min(dim(ct)) - 1)))   # Cramer's V

###############################################################################
## Task 5: Predictive Statistical Modelling
###############################################################################
# Stratified 70/30 split (keeps the class ratio equal in train and test)
set.seed(123)
idx_yes <- which(diabetes_data$diabetes == "Yes"); idx_no <- which(diabetes_data$diabetes == "No")
train_index <- c(sample(idx_yes, 0.7 * length(idx_yes)), sample(idx_no, 0.7 * length(idx_no)))
train_data <- diabetes_data[train_index, ]
test_data  <- diabetes_data[-train_index, ]
dim(train_data); dim(test_data)

# Predictors: team's original set + HighChol, PhysActivity, Stroke, MentHlth,
# DiffWalk, Income, Education (justify with Task 4 findings + literature)
model_formula <- diabetes ~ Age + Sex + BMI + HighBP + HighChol + HeartDiseaseorAttack +
  Stroke + PhysActivity + Smoker + GenHlth + PhysHlth + MentHlth + DiffWalk + Income + Education

logit_model <- glm(model_formula, data = train_data, family = binomial)
summary(logit_model)

# Multicollinearity (GVIF; < 5 is acceptable)
vif_vals <- vif(logit_model); vif_vals

# Odds ratios with 95% CI
or_tbl <- round(exp(cbind(OR = coef(logit_model), confint.default(logit_model))), 3)
or_tbl; write.csv(or_tbl, "tables/odds_ratios.csv")

# Assumption checks: linearity of logit (Box-Tidwell style) and influential points
bt <- glm(update(model_formula, . ~ . + I(BMI * log(BMI)) + I(Age * log(Age))), data = train_data, family = binomial)
round(summary(bt)$coefficients[c("I(BMI * log(BMI))", "I(Age * log(Age))"), ], 4)
cd <- cooks.distance(logit_model)
sum(cd > 4 / nrow(train_data)); max(cd)
# Independence: BRFSS is a complex survey (weights ignored) -> state as a limitation.

# Forward and backward stepwise selection
null_model <- glm(diabetes ~ 1, data = train_data, family = binomial)
step_model <- step(null_model, scope = list(lower = null_model, upper = logit_model),
                   direction = "forward", trace = FALSE)
back_model <- step(logit_model, direction = "backward", trace = FALSE)
summary(step_model)
length(coef(step_model)) - 1; length(coef(back_model)) - 1; length(coef(logit_model)) - 1

# Penalised models
x_train <- model.matrix(model_formula, data = train_data)[, -1]
x_test  <- model.matrix(model_formula, data = test_data)[, -1]
y_train <- train_data$diabetes; y_test <- test_data$diabetes
set.seed(123); lasso_model <- cv.glmnet(x_train, y_train, family = "binomial", alpha = 1)
set.seed(123); ridge_model <- cv.glmnet(x_train, y_train, family = "binomial", alpha = 0)
set.seed(123); enet_model  <- cv.glmnet(x_train, y_train, family = "binomial", alpha = 0.5)
lasso_model$lambda.min; lasso_model$lambda.1se
coef(lasso_model, s = "lambda.1se")            # zeros = variables dropped
save_fig("13_lasso_cv.png", plot(lasso_model))

# ---- Evaluation helper: metrics at 0.5 AND at the Youden cutoff chosen on TRAIN ----
evaluate <- function(name, p_tr, p_te) {
  p_tr <- as.numeric(p_tr); p_te <- as.numeric(p_te)
  thr_y <- as.numeric(coords(roc(train_data$diabetes, p_tr, quiet = TRUE), "best",
                             best.method = "youden", ret = "threshold"))[1]
  a <- as.numeric(auc(roc(test_data$diabetes, p_te, quiet = TRUE)))
  mk <- function(thr, label) {
    pred <- p_te > thr; act <- test_data$diabetes == "Yes"
    TP <- sum(pred & act); FP <- sum(pred & !act); FN <- sum(!pred & act); TN <- sum(!pred & !act)
    data.frame(Model = name, Threshold = label, Cutoff = round(thr, 3), Accuracy = (TP + TN) / length(act),
               Sensitivity = TP / (TP + FN), Specificity = TN / (TN + FP),
               Precision = TP / max(TP + FP, 1), F1 = 2 * TP / (2 * TP + FP + FN), AUC = a)
  }
  rbind(mk(0.5, "0.5"), mk(thr_y, "Youden"))
}
p_of <- function(m, ...) predict(m, ..., type = "response")

model_comparison <- rbind(
  evaluate("Logistic (full)",     p_of(logit_model, train_data), p_of(logit_model, test_data)),
  evaluate("Logistic (forward)",  p_of(step_model, train_data),  p_of(step_model, test_data)),
  evaluate("Logistic (backward)", p_of(back_model, train_data),  p_of(back_model, test_data)),
  evaluate("LASSO",       p_of(lasso_model, newx = x_train, s = "lambda.1se"), p_of(lasso_model, newx = x_test, s = "lambda.1se")),
  evaluate("Ridge",       p_of(ridge_model, newx = x_train, s = "lambda.1se"), p_of(ridge_model, newx = x_test, s = "lambda.1se")),
  evaluate("Elastic Net", p_of(enet_model,  newx = x_train, s = "lambda.1se"), p_of(enet_model,  newx = x_test, s = "lambda.1se")))
model_comparison[, 4:9] <- round(model_comparison[, 4:9], 3)
print(model_comparison, row.names = FALSE)
write.csv(model_comparison, "tables/model_comparison.csv", row.names = FALSE)
# INTERPRETATION: at 0.5 accuracy looks good but sensitivity is low (imbalance).
# The Youden cutoff raises sensitivity - what a screening programme needs. AUCs
# are near-identical (n ~ 200k, 16 predictors), so RECOMMEND the simplest
# interpretable model (logistic regression) - state this explicitly in the report.

# ROC curves, calibration, cross-validation, sensitivity analysis
save_fig("14_roc.png", {
  plot(roc(test_data$diabetes, p_of(logit_model, test_data), quiet = TRUE), col = "#4C9BE8", lwd = 2, main = "ROC Curves - Test Set")
  plot(roc(test_data$diabetes, as.numeric(p_of(lasso_model, newx = x_test, s = "lambda.1se")), quiet = TRUE), add = TRUE, col = "#E8734C", lwd = 2, lty = 2)
  legend("bottomright", c("Logistic", "LASSO"), col = c("#4C9BE8", "#E8734C"), lwd = 2, lty = 1:2, bty = "n")
})
pt <- p_of(logit_model, test_data); dec <- cut(pt, quantile(pt, 0:10 / 10), include.lowest = TRUE)
calib <- data.frame(Predicted = tapply(pt, dec, mean), Observed = tapply(test_data$diabetes == "Yes", dec, mean))
save_fig("15_calibration.png", { plot(calib$Predicted, calib$Observed, pch = 19, col = "#4C9BE8", xlab = "Mean predicted risk",
                                      ylab = "Observed proportion", main = "Calibration (deciles)"); abline(0, 1, lty = 2) })

set.seed(123)
folds <- sample(rep(1:5, length.out = nrow(diabetes_data)))
cv_auc <- sapply(1:5, function(k) {
  m <- glm(model_formula, data = diabetes_data[folds != k, ], family = binomial)
  as.numeric(auc(roc(diabetes_data$diabetes[folds == k], p_of(m, diabetes_data[folds == k, ]), quiet = TRUE)))
})
round(cv_auc, 3); round(mean(cv_auc), 3)                 # 5-fold CV AUC

logit_strict <- glm(update(model_formula, diab_strict ~ .), data = train_data, family = binomial)
auc(roc(test_data$diab_strict, p_of(logit_strict, test_data), quiet = TRUE))   # strict target

###############################################################################
## Task 6: Experimental Design (CRD vs RCBD) - ILLUSTRATIVE DEMOS ONLY
## (no experiment was run; use these to support the written evaluation)
###############################################################################
diabetes_data$AgeBlock <- cut(diabetes_data$Age, c(0, 4, 8, 13), labels = c("18-44", "45-64", "65+"))
crd  <- aov(BMI ~ GenHlth, data = diabetes_data)                 # ignores age (CRD-style)
rcbd <- aov(BMI ~ AgeBlock + GenHlth, data = diabetes_data)      # age as block (RCBD-style)
c(CRD = deviance(crd) / df.residual(crd), RCBD = deviance(rcbd) / df.residual(rcbd))
# INTERPRETATION: lower error mean square = block removed nuisance variation ->
# more power. BRFSS is observational, so this only illustrates the mechanism.

# Sample size for a future randomised lifestyle-intervention trial
p_ctrl <- mean(diabetes_data$diabetes == "Yes")
ceiling(power.prop.test(p1 = p_ctrl, p2 = p_ctrl * 0.85, power = 0.8, sig.level = 0.05)$n)   # per arm

# Simulated trial: power of CRD vs RCBD (age blocks)
sim_trial <- function(design, n_per_cell = 40, effect = -1.0) {
  block <- factor(rep(c("18-44", "45-64", "65+"), each = 2 * n_per_cell))
  trt <- factor(rep(rep(c("Control", "Programme"), each = n_per_cell), 3))
  if (design == "CRD") trt <- sample(trt)
  y <- 27 + c("18-44" = -2, "45-64" = 1, "65+" = 3)[as.character(block)] +
    ifelse(trt == "Programme", effect, 0) + rnorm(length(block), 0, 3)
  fit <- if (design == "CRD") aov(y ~ trt) else aov(y ~ block + trt)
  p <- summary(fit)[[1]][["Pr(>F)"]]
  p[length(p) - 1]
}
set.seed(2024)
sapply(c("CRD", "RCBD"), function(d) mean(replicate(500, sim_trial(d)) < 0.05))   # simulated power

###############################################################################
## Task 7: Principal Component Analysis
###############################################################################
pca_vars <- c("Age", "BMI", "MentHlth", "PhysHlth", "Income", "Education", "GenHlth_num")
pca_result <- prcomp(diabetes_data[, pca_vars], center = TRUE, scale. = TRUE)
summary(pca_result)                       # variance explained
round(pca_result$rotation, 3)             # loadings
save_fig("16_pca_scree.png", {
  ve <- pca_result$sdev^2 / sum(pca_result$sdev^2)
  b <- barplot(ve * 100, names.arg = paste0("PC", seq_along(ve)), col = "#4C9BE8", ylab = "% variance", main = "PCA Scree Plot")
  lines(b, cumsum(ve) * 100, type = "b", pch = 19, col = "#E8734C")
})
save_fig("17_pca_biplot.png", biplot(pca_result, cex = 0.5, main = "PCA Biplot"), h = 700)
sum(pca_result$sdev^2 > 1)                # Kaiser rule: PCs to keep
gv <- if (is.matrix(vif_vals)) vif_vals[, 3]^2 else vif_vals
max(gv)                                   # low -> PCA not needed for multicollinearity

# Impact on prediction: first k PCs vs the original numeric variables
k <- sum(pca_result$sdev^2 > 1)
pcs_tr <- predict(pca_result, train_data[, pca_vars])[, 1:k, drop = FALSE]
pcs_te <- predict(pca_result, test_data[, pca_vars])[, 1:k, drop = FALSE]
m_pc  <- glm(train_data$diabetes ~ pcs_tr, family = binomial)
m_org <- glm(diabetes ~ Age + BMI + MentHlth + PhysHlth + Income + Education + GenHlth_num, data = train_data, family = binomial)
auc_pc  <- auc(roc(test_data$diabetes, as.numeric(plogis(cbind(1, pcs_te) %*% coef(m_pc))), quiet = TRUE))
auc_org <- auc(roc(test_data$diabetes, p_of(m_org, test_data), quiet = TRUE))
c(PCs = as.numeric(auc_pc), Original = as.numeric(auc_org))
# INTERPRETATION: PCA is NOT recommended here - few predictors, mostly binary
# (PCA assumes continuous data), low multicollinearity, and PCs lose the
# interpretability (odds ratios) management needs.

###############################################################################
## Task 8: Bayesian Statistical Methods
###############################################################################
# ---- Naive Bayes ----
nb_model <- naiveBayes(diabetes ~ Age + Sex + BMI + HighBP + HighChol + HeartDiseaseorAttack +
                         PhysActivity + Smoker + PhysHlth + DiffWalk + GenHlth + Income + Education,
                       data = train_data)
nb_p_tr <- predict(nb_model, train_data, type = "raw")[, "Yes"]
nb_p_te <- predict(nb_model, test_data,  type = "raw")[, "Yes"]

# ---- Bayesian logistic regression (weakly-informative priors) ----
bayes_model <- bayesglm(model_formula, data = train_data, family = binomial(link = "logit"))
summary(bayes_model)

bayes_comparison <- rbind(evaluate("Naive Bayes", nb_p_tr, nb_p_te),
                          evaluate("Bayesian logistic", p_of(bayes_model, train_data), p_of(bayes_model, test_data)))
bayes_comparison[, 4:9] <- round(bayes_comparison[, 4:9], 3)
print(bayes_comparison, row.names = FALSE)
max(abs(coef(logit_model) - coef(bayes_model)))     # MLE vs Bayesian: tiny difference
# INTERPRETATION: with >150k observations the data overwhelm a weak prior, so
# Bayesian = classical. Bayesian methods help with SMALL samples, rare outcomes
# or real prior knowledge. Naive Bayes assumes independent predictors (BMI, BP,
# age are correlated) -> poorly calibrated probabilities.

# ---- Bayesian inference: posterior prevalence (Beta(1,1) prior) by High BP ----
post <- function(g) {
  x <- sum(diabetes_data$diabetes[diabetes_data$HighBP == g] == "Yes"); n <- sum(diabetes_data$HighBP == g)
  c(mean = (1 + x) / (2 + n), lo = qbeta(.025, 1 + x, 1 + n - x), hi = qbeta(.975, 1 + x, 1 + n - x))
}
round(rbind(NoHighBP = post("No"), HighBP = post("Yes")), 4)       # 95% credible intervals
round(qbeta(c(.025, .975), 1 + 8, 1 + 22), 3)                      # same 25% with n = 30: much wider

# ---- Bayesian decision making: expected-cost threshold ----
# Missing a case (FN) costs more than a false alarm (FP). Replace costs with
# values from your industry expert. Optimal rule: flag if P > C_FP / (C_FP + C_FN).
C_FN <- 5; C_FP <- 1
p_te_b <- p_of(bayes_model, test_data); act <- test_data$diabetes == "Yes"
cost_at <- function(t) { pr <- p_te_b > t; (C_FN * sum(!pr & act) + C_FP * sum(pr & !act)) / length(act) }
grid <- seq(0.05, 0.6, 0.01); costs <- sapply(grid, cost_at)
C_FP / (C_FP + C_FN); grid[which.min(costs)]               # theoretical vs empirical cutoff
c(at_0.5 = cost_at(0.5), at_optimal = min(costs))
save_fig("18_decision_cost.png", { plot(grid, costs, type = "l", lwd = 2, col = "#4C9BE8", xlab = "Decision threshold",
         ylab = "Expected cost per person", main = "Bayesian Decision Analysis (FN = 5, FP = 1)")
         abline(v = grid[which.min(costs)], lty = 2, col = "#E8734C") })

###############################################################################
# TASK 9 - TIME SERIES (SIMULATED ILLUSTRATION)
# BRFSS 2015 is a single cross-section: NO time dimension. The series below is
# SIMULATED to show the workflow. Label it as a demo in the report and state
# which real data (monthly screening counts / annual prevalence) to collect.
###############################################################################
set.seed(99)
months <- 120
sim <- 400 + 2.5 * (1:months) + 40 * sin(2 * pi * (1:months) / 12) + rnorm(months, 0, 18)
ts_dm <- ts(round(sim), start = c(2015, 1), frequency = 12)

save_fig("19_ts_decomposition.png", plot(decompose(ts_dm), col = "#4C9BE8"), h = 700)
train_ts <- window(ts_dm, end = c(2023, 12)); test_ts <- window(ts_dm, start = c(2024, 1))
arima_fit <- auto.arima(train_ts, seasonal = TRUE)
print(arima_fit)
fc <- forecast(arima_fit, h = 12)
print(round(accuracy(fc, test_ts)[, c("RMSE", "MAE", "MAPE")], 2))
Box.test(residuals(arima_fit), lag = 24, type = "Ljung-Box")        # residual check
save_fig("20_ts_forecast.png", { plot(fc, main = "ARIMA Forecast (simulated monthly screenings)", ylab = "Cases")
                                 lines(test_ts, col = "#E8734C", lwd = 2) })
# INTERPRETATION: trend -> capacity planning; seasonality -> staffing/campaign
# timing; forecast intervals -> budgeting. Needs stationarity and no structural breaks.

###############################################################################
# TASK 10 - INNOVATION PROTOTYPE: DIABETES EARLY-WARNING RISK SCORE
# Framework: data intake -> cleaning -> logistic risk model -> cost-based
# threshold -> risk tier (Low/Moderate/High) -> action -> feedback & recalibration
###############################################################################
final_model <- back_model                                    # parsimonious logistic model
risk_cut <- as.numeric(quantile(p_of(final_model, train_data), c(0.5, 0.85)))
risk_score <- function(newdata) {
  p <- p_of(final_model, newdata)
  data.frame(Probability = round(p, 3), Tier = cut(p, c(-Inf, risk_cut, Inf), labels = c("Low", "Moderate", "High")))
}
head(cbind(test_data[, c("Age", "BMI", "HighBP", "GenHlth")], risk_score(test_data)), 8)   # sample output
round(tapply(test_data$diabetes == "Yes", risk_score(test_data)$Tier, mean), 3)            # observed rate by tier

###############################################################################
# Save cleaned dataset
###############################################################################
write.csv(diabetes_data, "diabetes_cleaned.csv", row.names = FALSE)
file.exists("diabetes_cleaned.csv")