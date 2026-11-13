# GitHub Upload Guide

## 1. Create the repository

1. Sign in to GitHub and select **New repository**.
2. Use the repository name `diabetes-risk-factor-analysis`.
3. Add a short description, for example: `R-based statistical analysis and predictive modelling of diabetes risk indicators using BRFSS 2015 data.`
4. Choose **Public** or **Private** according to your lecturer's guidance and your group's agreement.
5. Do not initialize the repository with another README, `.gitignore`, or license because this project folder already contains its README and `.gitignore`.

## 2. Upload the project

The simplest option is to open the new empty repository, choose **Add file → Upload files**, and upload the contents of this project folder. Keep the folder structure intact. Commit the upload with a message such as `Add project analysis and documentation`.

Alternatively, use Git from a terminal opened inside this folder:

```bash
git init
git add .
git commit -m "Add diabetes risk analysis project"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/diabetes-risk-factor-analysis.git
git push -u origin main
```

Replace `YOUR-USERNAME` with your GitHub username and use the repository URL GitHub gives you.

## 3. Before making the repository public

- Add the exact BRFSS dataset source, download URL, access date and citation to `data/README.md` and the main README.
- Confirm that the approximate 75% contribution statement is accurate and agreed with your group.
- Check that no private, identifiable or restricted data are included.
- Run the R script locally after placing the dataset in `data/`.
- Review the generated tables and figures before adding any of them to the repository.
- Add your research references and any required AI/tool acknowledgements.

The dataset CSV and generated `results/diabetes_outputs/` files are ignored by Git by default. This is intentional; do not force-add the dataset or large generated files without checking their source, licence and suitability for public sharing.
