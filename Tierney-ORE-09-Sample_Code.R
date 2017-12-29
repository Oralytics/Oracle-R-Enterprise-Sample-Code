#
# Oracle R Enterprise Book - by Brendan Tierney
#    Published by : McGraw-Hill / Oracle Press
#
# Chapter 9 - Creating ORE Scripts
#

library(ORE)

ore.connect(user="ore_user", service_name="pdb12c", host="localhost", password="ore_user", port=1521, all=TRUE)

options("ore.warn.order")
options(ore.warn.order=FALSE)

ore.ls()

#
# using ore.scriptCreate to create a user defined R script
#
?ore.scriptCreate

# Create a script to calculate the approximate age of a person based on birth year
ore.scriptCreate("CustomerAge", function (YearBorn) {
  CustAge <- as.numeric(format(Sys.time(), "%Y")) - YearBorn
  data.frame(CustAge)
})

#Example of calling an ORE Script using the ore.doEval() function
# Call the script to calculate the age. Returns an ore.object
res <- ore.doEval(FUN.NAME="CustomerAge", YearBorn=2010)      
class(res)      
res



# Create a script to calculate the approximate age of a person based on birth year
# with the global parameter set to TRUE
ore.scriptDrop("CustomerAge")
ore.scriptCreate("CustomerAge", function (YearBorn) {
  CustAge <- as.numeric(format(Sys.time(), "%Y")) - YearBorn
  data.frame(CustAge)
}, global=TRUE)

# Create a script to calculate the approximate age of a person based on birth year
# with the overwrite parameter set to TRUE, also set global=FALSE by default
ore.scriptCreate("CustomerAge", function (YearBorn) {
  CustAge <- as.numeric(format(Sys.time(), "%Y")) - YearBorn
  data.frame(CustAge)
}, overwrite=TRUE)


ore.scriptDrop("CustomerAge")

#
# ore.grant() and ore.revoke
#
?ore.grant

ore.grant("CustomerAge", type = "rqscript", "DMUSER")


ore.connect(user="dmuser", service_name="pdb12c", host="localhost", password="dmuser", port=1521, all=TRUE)

# Call the script to calculate the age. Returns an ore.object
BirthYear = as.numeric(2005)      
res <- ore.doEval(FUN.NAME="CustomerAge", YearBorn=BirthYear)      
res

ore.connect(user="ore_user", service_name="pdb12c", host="localhost", password="ore_user", port=1521, all=TRUE)

ore.revoke("CustomerAge", type = "rqscript", "DMUSER")



#
# Managing your ORE Scripts
#
?ore.scriptList
# list all the scripts available for the user
ore.scriptList()
# list the scripts based on the different types
ore.scriptList(type="all")
ore.scriptList(type="user")
ore.scriptList(type="global")
ore.scriptList(type="grant")
ore.scriptList(type="granted")
ore.scriptList(name="CustomerAge")
# search for ORE scripts that contain a string pattern as part of their name
ore.scriptList(pattern="Cust")


?ore.scriptLoad
ore.scriptLoad(name="CustomerAge", newname="CUSTAGE")
CUSTAGE(2003)




