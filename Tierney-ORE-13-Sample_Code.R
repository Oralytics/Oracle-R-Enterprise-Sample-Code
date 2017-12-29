#
# Oracle R Enterprise Book - by Brendan Tierney
#    Published by : McGraw-Hill / Oracle Press
#
# Chapter 13 - Using ORE in APEX and OBIEE
#

-- Create R script to aggregate on the AGE attributeBEGIN   --sys.rqScriptDrop('AgeProfile1');   sys.rqScriptCreate('AgeProfile1',      'function(dat) {           aggdata <- aggregate(dat$AFFINITY_CARD,                                by = list(Age = dat$AGE),                                FUN = length)      } ');                        END;-- Call the AgeProfile1 script passing in the data from MINING_DATA_BUILD_Vselect *from table (rqTableEval(cursor(select* from MINING_DATA_BUILD_V),                   NULL,                  ‘select 1 AGE, 1 AGE_NUM, from dual’,	                  ‘AgeProfile1’));—- Create R script to create different plots
—- Requires ggplot to be installed on DB serverBEGIN    --sys.rqScriptDrop('AgeProfile2');    sys.rqScriptCreate('AgeProfile2',       'function(dat) {            library(ggplot)           res <- ggplot(data=mdbv, aes(AGE, fill=HOUSEHOLD_SIZE) ) +
                         geom_histogram(color = "white") +
                         facet_grid(CUST_GENDER ~ .) +
                         ggtitle("Household Size, Age Distributions by Gender")         } ');                         END;—- Display the image from the AgeProfile2 R scriptselect image from table(rqTableEval(cursor(select * from MINING_DATA_BUILD_V),                    NULL,                    'PNG',  	            'AgeProfile2') )