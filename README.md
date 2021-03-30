# Swetagging2021
 This repository contains the supplementary materials for the NODALIDA paper

Yvonne Adesam and Aleksandrs Berdicevskis. 2021. "Part-of-speech tagging of Swedish texts in the neural era".

The "Regression" folder contains the scripts and data that are necessary to reproduce the results reported in section 4.5 in the paper. The RegrInput subfolder contains the necessary input (the concatenated test sets from the five folds from every corpus). calculate_regr.rb script (run as "ruby calculate_regr.rb") fills the RegrOutput folder, calculating the relevant predictors, regression.r runs the regression analysis (run in R, the "languageR" library must be pre-installed). See comments in the scripts for the further details.

The "Ensemble" folder contains the scripts and data that are necessary to reproduce the results reported in section 4.6 in the paper. The Ruby gem NBayes must be installed ("gem install nbayes") before running the nb_ensemble.rb script
