#
# Oracle R Enterprise Book - by Brendan Tierney
#    Published by : McGraw-Hill / Oracle Press
#
# Chapter 11 - Oracle R Advanced Analytics for Hadoop
#

library(ORCH)

# Check our the demonstrations for ORCH
demo(package="ORE")
demo(package="ORCH")
demo(hive_basic , package="ORCH")
demo(hdfs_aggregate , package="ORCH")

apropos("^orch")
apropos("^hdfs")
apropos("^hadoop")
apropos("^spark")

ls("package:ORCHcore")
ls("package:ORCHstats")


# Connect to Hive
ore.connect(type="HIVE")
ore.attach()

# Connect to HIVE. The following environment variables must be set:# HIVE_SERVER - hostname or IP of HiveServer2 to connect to;# HIVE_PORT - HiveServer2 port to connect to;# HIVE_USER - Hive user name to use;# HIVE_PASSWORD - Hive user password to use;# HIVE_DATABASE - Hive detabase name (i.e. schema) to use.ore.connect( host = Sys.getenv("HIVE_SERVER"),             port = Sys.getenv("HIVE_PORT"),             user = Sys.getenv("HIVE_USER"),             password = Sys.getenv("HIVE_PASSWORD"),             schema = Sys.getenv("HIVE_DATABASE"),             type = "HIVE")ore.attach()


# Download the White Wine data set
WhiteWine = read.table("http://archive.ics.uci.edu/ml/machine-learning-databases/wine-quality/winequality-white.csv", sep=";", header=TRUE)
# Get some of the details of the data set based on local R data frame
dim(WhiteWine)
names(WhiteWine)
head(WhiteWine)
table(WhiteWine$quality)


# Push the R data frame to Hive.  wine_table now points to a Hive table.
wine_table <- ore.push(WhiteWine)
# Check that wine_table is and ORE data frame
class(wine_table)
# Performs some statistics on the data set in Hive
nrow(wine_table)
summary(wine_table)


# Take the downloaded data set in an R data frame and push to HDFS
wine_hdfs <- hdfs.put(WhiteWine)
# Generate a linear model on the data stored on HDFS
LMmodel_hdfs <- orch.lm(alcohol  ~., wine_hdfs) 
# View the model details
LMmodel_hdfs
summary(LMmodel_hdfs)
# Remove the data set from HDFS rm(wine_hdfs) # remove the model
rm(LMmodel_hdfs)


ore.connect(type="HIVE")
IRIS_data <- iris 
# Inspect the structure of the iris data. You will see the Species has a Factor data type
str(IRIS_data)
# Try writing this data set to Hive and we get an error
IRIS_hive <- ore.push(IRIS_data)

# convert the factor data type to string
factfilt <- sapply(IRIS_data, is.factor)
factfilt
IRIS_data[factfilt] <- data.frame(lapply(IRIS_data[factfilt], as.character), stringsAsFactors = FALSE)
str(IRIS_data)
# Try writing this data set to Hive again
IRIS_hive <- ore.push(IRIS_data)
# Success
class(IRIS_hive)


# Map-reduce
#
# Write the White Wine data set out to HDFS
WhiteWine.dfs <- hdfs.put(WhiteWine, key='quality')

# Submit the hadoop job with mapper and reducer R scripts
mrRes <- try(hadoop.run(
             WhiteWine.dfs,
             mapper = function(key, val) {
                         orch.keyvals(key, val)
                      },
             reducer = function(key, vals) {
                   X <- sum(vals$residual.sugar)/nrow(vals)
                   orch.keyval(key, X)
                },
             config = new("mapred.config",
                          map.tasks = 1,
                          reduce.tasks = 1 )
     ), silent = TRUE)

# Print the results of the mapreduce job
class(mrRes)
mrRes
hdfs.get(mrRes)


# Spark examples
# First you need to load the ORCH R package
library(ORCH)
# Create the Spark connection using Yarn
spark.connect("yarn-client", memory="512m", dfs.namenode="bigdatalite.localdomain")

# Load the rpart library as it contains the kyphosis data set
library(rpart)
# Write the data set to HDFS
dfs.dat <- hdfs.put(kyphosis)
# Call the orch.glm2 function to generate the model
sparkModel <- orch.glm2(Kyphosis ~ Age + Number + Start, dfs.dat = dfs.dat)

# Disconnect from Spark
spark.disconnect()


