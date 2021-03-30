#This script will run the linear-regression analysis, output the model coefficients and R2 values to the regr.txt file. Before you run it, set the current directory in R to RegrOutput and install the library languageR

options(scipen=999) #turn off the scientific notation

#running on one of the corpora (comment/uncomment to choose the one you want)
dataset <- read.csv("Eukalyptus_test_regr.tsv",sep = "\t", dec=".", header = TRUE)
#dataset <- read.csv("TalbankenSBX_test_regr.tsv",sep = "\t", dec=".", header = TRUE)
#dataset <- read.csv("TalbankenUD_test_regr.tsv",sep = "\t", dec=".", header = TRUE)

library(languageR) #loading a library necessary to check for collinearity, must be installed first
print(collin.fnc(dataset, c(7,8,9,10))$cnumber) #checking for collinearity as recommended by Baayen (2008)

sink("regr.txt") #redirecting the output to the regr.txt file (in the RegrOutput directory)

m1 <- lm(X1Bert ~ Freq + ttr + entr_token + entr_ending, data = dataset)
print(summary(m1)$coefficients)
print(summary(m1)$r.squared)

m1 <- lm(X2Flair ~ Freq + ttr + entr_token + entr_ending, data = dataset)
print(summary(m1)$coefficients)
print(summary(m1)$r.squared)

m1 <- lm(X3Stanza ~ Freq + ttr + entr_token + entr_ending, data = dataset)
print(summary(m1)$coefficients)
print(summary(m1)$r.squared)

m1 <- lm(X4Marmot ~ Freq + ttr + entr_token + entr_ending, data = dataset)
print(summary(m1)$coefficients)
print(summary(m1)$r.squared)

m1 <- lm(X5Hunpos ~ Freq + ttr + entr_token + entr_ending, data = dataset)
print(summary(m1)$coefficients)
print(summary(m1)$r.squared)
sink()


