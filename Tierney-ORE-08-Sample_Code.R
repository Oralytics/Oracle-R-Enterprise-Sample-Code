#
# Oracle R Enterprise Book - by Brendan Tierney
#    Published by : McGraw-Hill / Oracle Press
#
# Chapter 8 - Building Models Using ORE models and R Packages
#

#
# Load the sample data set for illustrating algorithms for classification
# Load the Adult Census Data data set
CensusIncome = read.table("http://archive.ics.uci.edu/ml/machine-learning-databases/adult/adult.data",
                  sep=",",header=F,col.names=c("age", "type_employer", "fnlwgt", "education", 
                                               "education_num","marital", "occupation", "relationship", "race","sex",
                                               "capital_gain", "capital_loss", "hr_per_week","country", "income"),
                    fill=FALSE, strip.white=T, na.strings = "Unknown")
dim(CensusIncome)
names(CensusIncome)
str(CensusIncome)
head(CensusIncome)
class(CensusIncome)


#
# Load the (white) Wine Quality Data data set - this data set will be used in examples
WhiteWine = read.table("http://archive.ics.uci.edu/ml/machine-learning-databases/wine-quality/winequality-white.csv", sep=";", header=TRUE)
dim(WhiteWine)
names(WhiteWine)
head(WhiteWine)
table(WhiteWine$quality)

#
# Load the (red) Wine Quility Data data set
#  This data set is not used in example but is provided here just in case you want to use it.
RedWine = read.table("http://archive.ics.uci.edu/ml/machine-learning-databases/wine-quality/winequality-red.csv", sep=";", header=TRUE)
dim(RedWine)
names(RedWine)
head(RedWine)


# Connecting to the Oracle Database
# First you need to load the ORE library
library(ORE) 

# Create an ORE connection to your Oracle Schema
ore.connect(user="ore_user", password="ore_user", host="localhost", service_name="PDB12C", port=1521, all=TRUE) 

options("ore.warn.order")
options(ore.warn.order=FALSE)
ore.ls()

#
# ORE GLM   ore.glm
#
?ore.glm()
census <- ore.push(CensusIncome)
str(census)
class(census)
GLMmodel <- ore.glm(income ~., data=census, family=binomial())
GLMscored <- predict(GLMmodel, newdata=census, supplemental.cols=c("age", "income"), type="response")
head(GLMscored, 20)


#
# ORE Linear Regression   ore.lm
#
?lm()
?ore.lm()
wine <- ore.push(WhiteWine)
LMmodel <- ore.lm(alcohol  ~., data=wine)
LMmodel
summary(LMmodel)

data_score <- wine[1:15,]
LMscored <- predict(LMmodel, newdata=data_score, supplemental.cols="alcohol")
LMscored

# ORE Stepwise  ore.stepwise
?ore.stepwise()
wine <- ore.push(WhiteWine)
SWmodel <- ore.stepwise(alcohol  ~. ^2, data=wine, add.p = 0.1, drop.p = 0.1)
summary(SWmodel)
?step()
# WARNING: The following steps function calls can take some minutes to run
SWsteps <- step(ore.lm(alcohol  ~ 1, data=wine), scope=terms(alcohol  ~. ^2, data=wine))
SWsteps <- step(ore.lm(alcohol  ~ 1, data=wine), scope=terms(alcohol  ~. ^2, data=wine), direction="forward")

#
# ORE Neural Network   ore.neural
#
?ore.neural()
wine <- ore.push(WhiteWine)
NNmodel <- ore.neural(quality ~., data=wine)
NNmodel <- ore.neural(quality ~., data=wine, hiddenSizes=c(5, 3, 2))
NNmodel
summary(NNmodel)

NNscored <- predict(NNmodel, newdata=wine, supplemental.col="quality")
head(NNscored)
str(ore.pull(NNscored))

#
# ORE Random Forest   ore.randomForest
#
?ore.randomForest
census <- ore.push(CensusIncome)
RFmodel <- ore.randomForest(income ~., data=census, ntree=10, confusion.matrix=TRUE)
RFmodel
names(RFmodel)
RFmodel$call
RFmodel$type
RFmodel$terms
RFmodel$ntree
RFmodel$mtry
RFmodel$classes
RFmodel$DOP
RFmodel$confusion
RFmodel$RFOPKG
summary(RFmodel)

RFscored <- predict(RFmodel, newdata=census, type="response", supplemental.cols="income")
head(RFscored, 10)
with(RFscored, table(income, prediction))


#
# Building models using R Packages and Algorithms
#
ore.doEval(function() row.names(installed.packages())) 

# Example using rpart on the Oracle Database server
library(rpart)
data <- ore.pull(census)
rpartModel <- rpart(income ~., method="class", data=data)
rpartModel
# Example using rpart with embedded R execution
rp <- ore.tableApply ( 
  ore.push(CensusIncome),
  function(dat) {
    library(rpart)
    Rmodel <- rpart(income ~., method="class", data=dat)
    pred_Income <- predict(Rmodel, dat, type="class")
    pred_Income2 <- cbind(dat, pred_Income)
    pred_Income2
  }
)
rp2 <- ore.pull(rp)
head(rp2)

# Example using rpart with embedded R execution with data in a Table
#ore.drop("CENSUS_INCOME")
census_data <- ore.create(CensusIncome, "CENSUS_INCOME")
rp <- ore.tableApply ( 
  CENSUS_INCOME,
  function(dat) {
    library(rpart)
    Rmodel <- rpart(income ~., method="class", data=dat)
    pred_Income <- predict(Rmodel, dat, type="class")
    pred_Income2 <- cbind(dat, pred_Income)
    pred_Income2
  }
)
class(rp)
rp2 <- ore.pull(rp)
class(rp2)
head(rp2)

?glm
wine <- ore.push(WhiteWine)
# Example using the standard glm function that comes with R
data <- ore.pull(wine)
gm <- glm(quality ~., data=data)
pred_Quality <- predict(gm, data)
pred_Quality2 <- cbind(data, pred_Quality)
head(pred_Quality2)

# now the embedded R execution method
GLMresult <- ore.tableApply ( 
  ore.push(WhiteWine),
  function(dat) {
    gm <- glm(quality ~., data=dat)
    pred_Quality <- predict(gm, dat)
    pred_Quality2 <- cbind(dat, pred_Quality)
    pred_Quality2
  }
)
GLMresult_scored <- ore.pull(GLMresult)
head(GLMresult_scored)

# kMeans 
km <- kmeans(WhiteWine, 5)
km

# Use embedded R execution to generate a kMean model
KMmodel <- ore.tableApply ( 
  ore.push(WhiteWine),
  function(dat) {
    km <- kmeans(dat, 5)
    km
  }
)
class(KMmodel)
km <- ore.pull(KMmodel)
class(km)
summary(km)
km

#
# ORE Predict   ore.predict
#
?ore.predict
library(rpart)
rpartModel <- rpart(income ~., method="class", data=CensusIncome)
rpartModel
# Score the data in the CENSUS_INCOME table
pred_Income <- ore.predict(rpartModel, CENSUS_INCOME, type="class")
pred_Income2 <- cbind(CENSUS_INCOME, pred_Income)
head(pred_Income2)
table(pred_Income2$income, pred_Income2$pred_Income)


gm <- glm(quality ~., data=WhiteWine)
# ore.drop("WHITE_WINE")
ore.create(WhiteWine, "WHITE_WINE")
pred_Quality <- ore.predict(gm, newdata=WHITE_WINE)
pred_Quality2 <- cbind(WHITE_WINE, pred_Quality)
head(pred_Quality2)


?kmeans
KMmodel <- kmeans(WhiteWine, centers=5)
KMmodel
pred_Cluster <- ore.predict(KMmodel, newdata=WHITE_WINE)
head(pred_Cluster)
pred_Cluster2 <- cbind(WHITE_WINE, pred_Cluster)
head(pred_Cluster2)

