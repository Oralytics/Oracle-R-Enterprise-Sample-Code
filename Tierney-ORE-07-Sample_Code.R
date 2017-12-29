#
# Oracle R Enterprise Book - by Brendan Tierney
#    Published by : McGraw-Hill / Oracle Press
#
# Chapter 7 - Building Models using ODM Algorithms
#

# Connecting to the Oracle Database
# First you need to load the ORE library
library(ORE) 

# Create an ORE connection to your Oracle Schema
#ore.connect(user="ore_user", password="ore_user", host="localhost", service_name="PDB12C", port=1521, all=TRUE) 
ore.connect(user="dmuser", password="dmuser", host="localhost", service_name="PDB12C", port=1521, all=TRUE) 

options("ore.warn.order")
options(ore.warn.order=FALSE)
ore.ls()


# Attribute Importance
?ore.odmAI()
ore.odmAI(AFFINITY_CARD ~., MINING_DATA_BUILD_V)

ore.ls()
ore.odmAI(LTV~., INSUR_CUST_LTV_SAMPLE)

# Association Rule Analysis
?ore.odmAssocRules()
# Build an Association Rules model using ore.odmAssocRules 
ore.exec("CREATE OR REPLACE VIEW AR_TRANSACTIONS 
         AS  
         SELECT s.cust_id || s.time_id  case_id, 
         p.prod_name 
         FROM   sh.sales s,
         sh.products p 
         WHERE s.prod_id = p.prod_id")  
# You need to sync the meta data for the newly created view to be visable in
#  your ORE session
ore.sync() 
ore.ls() 

# List the attributes of the AR_TRANSACTION view
names(AR_TRANSACTIONS)  
# Generate the Association Rules model
ARmodel <- ore.odmAssocRules(~., AR_TRANSACTIONS, case.id.column = "CASE_ID",                                
                             item.id.column = "PROD_NAME", min.support = 0.06, min.confidence = 0.1) 
# List the various pieces of information that is part of the model
names(ARmodel) 
# List all the information about the model
summary(ARmodel)
# To examine the individual elements of the model 
ARmodel$name
ARmodel$settings
ARmodel$attributes
ARmodel$inputType
ARmodel$formula
ARmodel$extRef
ARmodel$call

# arules comes as one of the supporting packages for ORE
library(arules)
# Extract the Association Rules to local client and inspect the rules
local_ARrules <- ore.pull(rules(ARmodel))
inspect(local_ARrules)
# extract a subset of the Association Rules
rules1 <- subset(rules(ARmodel), min.confidence=0.7, orderby="lift")
rules1

# Extract the Itemsets to local client and inspect
local_ARitemsets <- ore.pull(itemsets(ARmodel))
inspect(local_ARitemsets)
# extract a subset of the itemsets
itemsets1 <- subset(itemsets(ARmodel), min.support=0.12)
itemsets1

# Decisions Trees
?ore.odmDT
# Create the Training and Test data sets using Split Sampling 
# 
full_dataset <- MINING_DATA_BUILD_V 
# add row indexing  to the data frame 
row.names(full_dataset) <- full_dataset$CUST_ID 
# Set the sample size to be 40% of the full data set 
#    The Testing data set will have 40% of the records 
#    The Training data set will have 60% of the records 
SampleSize <- nrow(full_dataset)*0.40 
# Create an index of records for the Sample 
Index_Sample <- sample(1:nrow(full_dataset), SampleSize) 
group <- as.integer(1:nrow(full_dataset) %in% Index_Sample) 
# Create a partitioned data set of those records not selected to be in sample 
Training_Sample <- full_dataset[group==FALSE,] 
# Create partitioned data set of records who were selected to be in the sample 
Testing_Sample <- full_dataset[group==TRUE,] 
# Check the number of records in each data set
nrow(Training_Sample)
nrow(Testing_Sample)
nrow(full_dataset)

# Build a Decision Tree model using ore.odmDT 
DTmodel <- ore.odmDT(AFFINITY_CARD ~., Training_Sample) 
class(DTmodel) 
names(DTmodel) 
summary(DTmodel)

# Test the Decision Tree model 
DTtest <- predict(DTmodel, Testing_Sample, "AFFINITY_CARD") 
# Generate the confusion Matrix 
with(DTtest, table(AFFINITY_CARD, PREDICTION))

head(DTtest)

# Apply the Decision Tree model to new data
#  Add row indexing for the data frame 
row.names(MINING_DATA_APPLY_V) <- MINING_DATA_APPLY_V$CUST_ID
# Score the new data with Decision Tree model
DTapply <- predict(DTmodel, MINING_DATA_APPLY_V) 
# Combine the Apply data set with the Predicted values
DTapplyResults <- cbind(MINING_DATA_APPLY_V, DTapply)
head(DTapplyResults)

# alternatice approach using the supplemental.cols
DTapply2 <- predict(DTmodel, newdata=MINING_DATA_APPLY_V, supplemental.cols=c("CUST_ID", "CUST_GENDER", "AGE"))
head(DTapply2,8)


# Support Vector Machine - Classification
?ore.odmSVM
# Build the Support Vector Machine model
SVMmodel <- ore.odmSVM(AFFINITY_CARD ~., Training_Sample, type="classification") 
class(SVMmodel) 
names(SVMmodel) 
summary(SVMmodel)
SVMmodel$attributes

# Test the Support Vector Machine model 
SVMtest <- predict(SVMmodel, Testing_Sample, "AFFINITY_CARD") 
# Generate the confusion Matrix 
with(SVMtest, table(AFFINITY_CARD, PREDICTION))

# Apply the Support Vector Machine model to new data
#  Add row indexing to the data frame 
row.names(MINING_DATA_APPLY_V) <- MINING_DATA_APPLY_V$CUST_ID
# Score the new data with Support Vector Machine model
SVMapply <- predict(SVMmodel, newdata=MINING_DATA_APPLY_V, supplemental.cols=c("CUST_ID", "CUST_GENDER", "AGE")) 
head(SVMapply)

# Support Vector Machines - Regression
#  Build regression model using SVM - shows how to exclude an attribute
SVMmodelReg <- ore.odmSVM(LTV ~. -LTV_BIN, INSUR_CUST_LTV_SAMPLE, type="regression") 
class(SVMmodelReg) 
names(SVMmodelReg) 
summary(SVMmodelReg)
SVMmodelReg$attributes

# Apply the SVM Regression model to new data
#  Add row indexing to the data frame 
row.names(INSUR_CUST_LTV_SAMPLE) <- INSUR_CUST_LTV_SAMPLE$CUSTOMER_ID
# Score the data
LTVapply <- predict(SVMmodelReg, newdata=INSUR_CUST_LTV_SAMPLE, supplemental.cols=c("CUSTOMER_ID", "STATE", "SEX", "AGE")) 
head(LTVapply)

head(INSUR_CUST_LTV_SAMPLE)

# Anomaly Detection using 1-Class Support Vector Machines
#  Add row indexing to the data frame 
row.names(CLAIMS) <- CLAIMS$POLICYNUMBER
#  Build the 1-Class SVM model
ADmodel <- ore.odmSVM(~. -POLICYNUMBER , CLAIMS, type="anomaly.detection", outlier.rate=0.02) 
class(ADmodel) 
names(ADmodel) 
summary(ADmodel)

# Apply model to identify the anomalous records
ADresults <- predict(ADmodel, CLAIMS, supplemental.cols="POLICYNUMBER")
head(ADresults)
nrow(ADresults)

# Naive Bayes - Classification
?ore.odmNB
# Build the Naive Bayes model
NBmodel <- ore.odmNB(AFFINITY_CARD ~., Training_Sample) 
class(NBmodel) 
names(NBmodel) 
summary(NBmodel)

# Test the Naive Bayes model 
NBtest <- predict(NBmodel, Testing_Sample, "AFFINITY_CARD") 
# Generate the confusion Matrix 
with(NBtest, table(AFFINITY_CARD, PREDICTION))

# Apply the Naive Bayes model to new data
#  Add row indexing to the data frame 
row.names(MINING_DATA_APPLY_V) <- MINING_DATA_APPLY_V$CUST_ID
# Score the new data with Naive Bayes model
NBapply <- predict(NBmodel, MINING_DATA_APPLY_V, supplemental.cols=c("CUST_ID", "CUST_GENDER", "AGE")) 
head(NBapply)


# Genearlized Linear Model (GLM) - Classification
?ore.odmGLM
Training_Sample$AFFINITY_CARD <- as.factor(Training_Sample$AFFINITY_CARD)
# Build the Generalized Linear Model
GLMmodel <- ore.odmGLM(AFFINITY_CARD ~ CUST_GENDER+AGE+COUNTRY_NAME+CUST_INCOME_LEVEL+EDUCATION+HOUSEHOLD_SIZE+YRS_RESIDENCE+FLAT_PANEL_MONITOR+HOME_THEATER_PACKAGE+Y_BOX_GAMES+OS_DOC_SET_KANJI, data=Training_Sample, auto.data.prep=TRUE, type="logistic")
class(GLMmodel)
names(GLMmodel)
summary(GLMmodel)
GLMmodel


#  Build regression model using Generalized Linear Model
GLMmodelReg <- ore.odmGLM(LTV ~ REGION+SEX+PROFESSION+AGE+HAS_CHILDREN+SALARY+HOUSE_OWNERSHIP+MARITAL_STATUS, data=INSUR_CUST_LTV_SAMPLE, type="normal") 
class(GLMmodelReg) 
names(GLMmodelReg) 
summary(GLMmodelReg)
GLMmodelReg

# Apply the Generalized Linear Model-Regression model to new data
#  Add row indexing to the data frame
row.names(INSUR_CUST_LTV_SAMPLE) <- INSUR_CUST_LTV_SAMPLE$CUSTOMER_ID
# Score the data
GLMapplyReg <- predict(GLMmodelReg, INSUR_CUST_LTV_SAMPLE, supplemental.cols=c("CUSTOMER_ID", "STATE", "SEX", "AGE","LTV"))
head(GLMapplyReg[,c("LTV", "PREDICTION")])
# Calculate the difference between predicted and actual values
GLMapplyReg$difference <- GLMapplyReg$PREDICTION - GLMapplyReg$LTV
GLMapplyReg$percent_diff <- (GLMapplyReg$difference/GLMapplyReg$LTV)*100
# Display subset of attributes and compare results
head(GLMapplyReg[,c("LTV", "PREDICTION", "difference", "percent_diff")])


# Building a Cluster Model
#  - k-Means
?ore.odmKMeans()
# Build a k-Means model for the INSUR_CUST_LTV_SAMPLE
#  Default num.centers=10
KMmodel <- ore.odmKMeans(~. -CUSTOMER_ID, data=INSUR_CUST_LTV_SAMPLE, num.centers=5, iterations=5)
KMmodel
summary(KMmodel)

# Predict what cluster a record belongs too.
KMapply <- predict(KMmodel, newdata=INSUR_CUST_LTV_SAMPLE, supplemental.cols=c("CUSTOMER_ID", "STATE", "SEX", "AGE","LTV"))
head(KMapply)

#  - O-Cluster
?ore.odmOC()
# Buil an O-Cluster model for the INSUR_CUST_LTV_SAMPLE
#  Default num.centers=10
OCmodel <- ore.odmOC(~. -CUSTOMER_ID, data=INSUR_CUST_LTV_SAMPLE, num.centers=5)
OCmodel
summary(OCmodel)

# Predict what cluster a record belongs too.
OCapply <- predict(OCmodel, newdata=INSUR_CUST_LTV_SAMPLE, supplemental.cols=c("CUSTOMER_ID", "STATE", "SEX", "AGE","LTV"))
head(OCapply)


# Saving the Data Mining object to and ORE data store
ore.save(list=c("Training_Sample", "Testing_Sample", "DTmodel"), name="ORE_DS_Decision_Tree", grantable=TRUE)
# List the ORE data stores
ore.datastore()
#ore.datastore(type="grantable")
# List the objects stored in the ORE data store
ore.datastoreSummary("ORE_DS_Decision_Tree")

# Load the ORE data store objects back into the R environment
ore.load("ORE_DS_Decision_Tree")
# Alternatively if you only want to reload the data sets
ore.load("ORE_DS_Decision_Tree", c("Training_Sample", "Testing_Sample"))

