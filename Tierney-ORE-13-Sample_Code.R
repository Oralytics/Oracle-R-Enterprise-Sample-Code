#
# Oracle R Enterprise Book - by Brendan Tierney
#    Published by : McGraw-Hill / Oracle Press
#
# Chapter 13 - Using ORE in APEX and OBIEE
#

-- Create R script to aggregate on the AGE attribute
—- Requires ggplot to be installed on DB server
                         geom_histogram(color = "white") +
                         facet_grid(CUST_GENDER ~ .) +
                         ggtitle("Household Size, Age Distributions by Gender")  