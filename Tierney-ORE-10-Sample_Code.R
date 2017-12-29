#
# Oracle R Enterprise Book - by Brendan Tierney
#    Published by : McGraw-Hill / Oracle Press
#
# Chapter 10 - Embedded R Execution
#

library(ORE)

ore.connect(user="ore_user", service_name="pdb12c", host="localhost", password="ore_user", port=1521, all=TRUE)

options("ore.warn.order")
options(ore.warn.order=FALSE)

ore.ls()

#
# ore.doEval() function
#
?ore.doEval
# Check the verion of R install on the Oracle Database server for ORE
ore.doEval(function() R.Version())
# Check R package version number. This packages is installed in ORE in Chapter 14
ore.doEval(function() packageVersion("e1071")) 

# Managing the format of the returned object
res <- ore.doEval(function() paste("Hello Brendan", "the time is", format(Sys.time(),"%X")))
# Display the result
res
# Check the class of the object
class(res)


# Return a ore.frame for the result of the function
res <- ore.doEval(function() data.frame(paste("Hello Brendan", "the time is", format(Sys.time(),"%X"))),
FUN.VALUE = data.frame(text_string = character(), stringsAsFactors = FALSE))
res
# Check that the class is now an ore.frame
class(res)

# Create a script to calculate the approximate age of a person based on birth year
ore.scriptDrop("CustomerAge")
ore.scriptCreate("CustomerAge", function (YearBorn) {
  CustAge <- as.numeric(format(Sys.time(), "%Y")) - YearBorn
  data.frame(CustAge)
}
)

#Example of calling an ORE Script using the ore.doEval() function
# Call the script to calculate the age. Returns an ore.object
ore.doEval(FUN.NAME="CustomerAge", YearBorn=2010)      
res <- ore.doEval(FUN.NAME="CustomerAge", YearBorn=2010)      
class(res)      
res

# Call the script to calculate the age. Returns an ore.frame
res2 <- ore.doEval(FUN.NAME="CustomerAge", YearBorn=2010,
                   FUN.VALUE=data.frame(Age=1))      
class(res2)      
res2


# Create a script to calculate the age difference to a reference value
ore.scriptDrop("CustomerAge2")
ore.scriptCreate("CustomerAge2", function (YearBorn) {
  ore.load("ORE_DS", refAge)
  CustAge <- as.numeric(format(Sys.time(), "%Y")) - YearBorn
  data.frame(CustAge-refAge)
}
)

# Call the script to calculate the age. Returns an ore.frame
res3 <- ore.doEval(FUN.NAME="CustomerAge2", YearBorn=2010,
                   FUN.VALUE=data.frame(Age=1), ore.connect=TRUE)      
class(res3)      
res3

# Use data in your schema
# connect to the DMUSER schema
ore.connect(user="dmuser", service_name="pdb12c", host="localhost", password="dmuser", port=1521, all=TRUE)
# aggregate the data based on AGE attribute
res4 <- ore.doEval(function(){
  ore.sync(table="MINING_DATA_BUILD_V")
  dat <- ore.pull(ore.get("MINING_DATA_BUILD_V"))
  aggdata <- aggregate(dat$AFFINITY_CARD,
                       by = list(Age = dat$AGE),
                       FUN = length)
}, FUN.VALUE=data.frame(AGE=1, AGE_NUM=1), ore.connect=TRUE)
res4
class(res4)

#
# ore.tableApply function
#
?ore.tableApply
# connect to the DMUSER schema
ore.connect(user="dmuser", service_name="pdb12c", host="localhost", password="dmuser", port=1521, all=TRUE)
# count the number of customer for each AGE
ageProfile <- ore.tableApply(MINING_DATA_BUILD_V, 
                  function(dat) {
                     aggdata <- aggregate(dat$AFFINITY_CARD,
                                          by = list(Age = dat$AGE),
                                          FUN = length)
                  },
                  FUN.VALUE=data.frame(AGE=1, AGE_NUM=1)
)
ageProfile
class(ageProfile)

res <- plot(ageProfile$AGE, ageProfile$AGE_NUM, type="l")

# Create a script to aggregate the data based on AGE attribute 
ore.scriptDrop("CustomerAge3")
ore.scriptCreate("CustomerAge3", function (dat) {
  aggdata <- aggregate(dat$AFFINITY_CARD,
                       by = list(Age = dat$AGE),
                       FUN = length)
}
)

# using ore.tableApply to call a script
ageProfile2 <- ore.tableApply(MINING_DATA_BUILD_V,
                              FUN.NAME="CustomerAge3",
                              FUN.VALUE=data.frame(Age=1, x=1)
)
class(ageProfile2)
head(ageProfile2)

#
# ore.groupApply function
#
?ore.groupApply
# calculate the mean Residual Sugar for each category of Wine Quality
avgAge <- ore.groupApply(WHITE_WINE, WHITE_WINE$quality, function(dat){
        avgSugar <- mean(dat$residual.sugar)
        data.frame(unique(dat$quality), avgSugar)
}, FUN.VALUE=data.frame(QUALITY=1, AVG_SUGAR=1))

class(avgAge)
avgAge

# calculate the mean Residual Sugar for each category of Wine Quality
avgAge2 <- ore.groupApply(WHITE_WINE, WHITE_WINE[,c("quality", "alcohol")], function(dat){
  avgSugar <- mean(dat$residual.sugar)
  data.frame(unique(dat$quality), unique(dat$alcohol), avgSugar)
}, FUN.VALUE=data.frame(QUALITY=1, ALCOHOL=1, AVG_SUGAR=1))

avgAge2

#
# ore.rowApply
#
?ore.rowApply
# ore.lm model created in chapter 8
LMmodel <- ore.lm(alcohol  ~., data=WHITE_WINE) 
LMmodel 
summary(LMmodel) 

# save the model to an ORE data store
ore.save(LMmodel, name="MODELS_DS")

# use ore.rowApply to use the LMmodel to predict the about of alcohol
# using the WHITE_WINE data set stored in our schema
amtAlcohol <- ore.rowApply(WHITE_WINE, function(dat){
  ore.load("MODELS_DS", list="LMmodel")
  LMscored <- predict(LMmodel, newdata=dat)
  lmRes <- cbind(dat, LMscored)
  res<- data.frame(alcohol=lmRes$alcohol, lmRes$LMscored)
  res
}, 
FUN.VALUE=data.frame(alcohol=1, LMscored=1),
ore.connect=TRUE,
rows=500)

class(amtAlcohol)
head(amtAlcohol)
amtAlcohol

# return the results as an ORE list to see results from each embedded R processes
amtAlcohol2 <- ore.rowApply(WHITE_WINE, function(dat){
  ore.load("MODELS_DS", list="LMmodel")
  LMscored <- predict(LMmodel, newdata=dat)
  lmRes <- cbind(dat, LMscored)
  res<- data.frame(alcohol=lmRes$alcohol, lmRes$LMscored)
  res
}, 
ore.connect=TRUE,
rows=500)

class(amtAlcohol2)
amtAlcohol2


#
# ore.indexApply
#
?ore.indexApply

idxSample <- ore.indexApply(5, function(index, dat, samplePercent){
  set.seed(index)
  # calculate the sample size
  SampleSize <- nrow(dat)*(samplePercent/100)
  # Create an index of records for the Sample 
  Index_Sample <- sample(1:nrow(dat), SampleSize) 
  group <- as.integer(1:nrow(dat) %in% Index_Sample) 
  # Create a sample data set
  sampleData <- dat[group==TRUE,] 
  res <- data.frame(sampleData[,1:4])
  },
dat=CUSTOMERS_USA,
samplePercent=2)

idxSample

#
# ore.parallel
#
?ore.parallel
options("ore.parallel")
options("ore.parallel" = 8)
options("ore.parallel" = TRUE)

