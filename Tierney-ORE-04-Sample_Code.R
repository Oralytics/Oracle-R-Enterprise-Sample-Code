#
# Oracle R Enterprise Book - by Brendan Tierney
#    Published by : McGraw-Hill / Oracle Press
#
# Chapter 4 - The ORE Transparency Layer
#

library(ORE)

ore.connect(user="ore_user", service_name="pdb12c", host="localhost", password="ore_user", port=1521, all=TRUE)
options(ore.warn.order=FALSE)

# pust the mtcars data set to the Oracle Database. It is created as a temporary object
cars_dataset <- ore.push(mtcars)

# check the class of the object. Should be an ore.frame object as it is pointing to
# a temporary object in the database.
class(cars_dataset) 

# list some of the ORE transparency layer information about the ore.frame
str(cars_dataset)

# What is the name of the table in the Database 
cars_dataset@sqlTable 
# Get the names of the attributes/variables 
cars_dataset@desc$name 

# using the names R function produces the same result
names(cars_dataset)

# Get the data types of the attributes/variables 
cars_dataset@desc$Sclass 
# Return the SQL Query used to retrieve the data from the table in the Database 
cars_dataset@dataQry 
# Display the first 5 records from the ORE table 
head(cars_dataset, 5)


df <- head(cars_dataset, 5)
str(df)
df@dataQry


# Aggregate the data in the CUSTOMER_V (a view based on the sh.customer table) 
#   Aggregate based on each value of Customer Gender 
AggData <- aggregate(CUSTOMER_V$CUST_ID, 
                       by = list(CUST_GENDER = CUSTOMER_V$CUST_GENDER),
                       FUN = length) 
# Display the results 
AggData 

# examine the transparency layer
str(AggData) 
AggData@dataQry 
AggData@dataObj 
AggData@desc$name 
AggData@sqlName 
AggData@sqlValue 
AggData@sqlTable 
AggData@sqlPred 
AggData@extRef 
AggData@row.names 
AggData@.Data


