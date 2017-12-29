#
# Oracle R Enterprise Book - by Brendan Tierney
#    Published by : McGraw-Hill / Oracle Press
#
# Chapter 10 - Embedded R Execution : SQL file
#


-- Create a script to approx. calculate the customer age.
BEGIN
   --sys.rqScriptDrop('CustomerAge3');
   sys.rqScriptCreate('CustomerAge3',
      'function(YearBorn = 2010) {
         CustAge <- data.frame(as.numeric(format(Sys.time(), "%Y")) - YearBorn)
      } ');
END;

-- query the ORE scripts that are in your schema
select * from user_rq_scripts;

-- Use the rqEval() function to run the CustomerAge ORE script
-- This script was created using R code
select *
from table(rqEval(cursor(select 2005 "YearBorn" from dual), 
                  'select 1 CustAge from dual',
                  'CustomerAge3') );
                  
-- Create the ORE Script to for the Hello Brendan example
BEGIN
   --sys.rqScriptDrop('HelloBrendan');
   sys.rqScriptCreate('HelloBrendan',
      'function() {
         res<-data.frame(paste("Hello Brendan", "the time is", format(Sys.time(),"%X")))
         res
      } ');
END;

-- Call the HelloBrendan ORE script
select *
from table(rqEval(NULL, 
                  'select cast(''a'' as varchar2(40)) "Ans" from dual',
                  'HelloBrendan') );


-- Call the AgeProfile1 script passing in the data from MINING_DATA_BUILD_V
select *
from table(rqTableEval(cursor(select * from MINING_DATA_BUILD_V), 
                  NULL,
                  'select 1 AGE, 1 AGE_NUM from dual',
                  'AgeProfile1') );
                  

-- Run the following in the DMUSER (Oracle Data Mining) schema                  
-- Create ORE Script to plot the aggregated values for AGE
BEGIN
   --sys.rqScriptDrop('AgeProfile2');
   sys.rqScriptCreate('AgeProfile2',
      'function(dat) {
           aggdata <- aggregate(dat$AFFINITY_CARD,
                                by = list(Age = dat$AGE),
                                FUN = length)
           res <- plot(aggdata$Age, aggdata$x, type = "l")                     
      } ');                        
END;

-- Call the AgeProfile2 script to create the chart of AGE profiles
select *
from table(rqTableEval(cursor(select * from MINING_DATA_BUILD_V), 
                  NULL,
                  'PNG',
                  'AgeProfile2') );
                  

-- Run the following in the ORE_USER schema. The data set is there.
--Phase 1: Creating the Data Mining model                  
-- Create a Linear Regression model and store in an ORE data store
BEGIN
   --sys.rqScriptDrop('DEMO_LM');
   sys.rqScriptCreate('DEMO_LM',
      'function(dat, ds_name) {
         mod <- lm(alcohol  ~., data=dat)
         ore.save(mod, name=ds_name, overwrite=TRUE)
      } ');
END;

-- Now you need to run the DEMO_LM ORE script to create the model
select *
from table(rqTableEval(cursor(select * from white_wine), 
                  cursor(select 1 as "ore.connect", 'DEMO_LM_DS' as "ds_name" from dual),
                  'XML',
                  'DEMO_LM') );
                  
-- Phase 2: Applying the Data Mining model                  
-- Create the script that applies the stored model to new data
--  Return the actual value and the predicted value
BEGIN
   --sys.rqScriptDrop('DEMO_LM_APPLY');
   sys.rqScriptCreate('DEMO_LM_APPLY',
      'function(dat, ds_name) {
         ore.load(ds_name)
         pre <- predict(mod, newdata=dat, supplemental.cols="alcohol")
         res <- cbind(dat, PRED=pre)
         res <- res[,c("alcohol", "PRED")]
      } ');
END;
                  
-- Run the apply script on the new data
select *
from table(rqTableEval(cursor(select * from white_wine), 
                  cursor(select 1 as "ore.connect", 'DEMO_LM_DS' as "ds_name" from dual),
                  'select 1 as "alcohol", 1 as "PRED" from dual',
                  'DEMO_LM_APPLY') );
                  

-- Using the rqGroupEval() function
BEGIN
   --sys.rqScriptDrop('DEMO_GROUP_EVAL');
   sys.rqScriptCreate('DEMO_GROUP_EVAL',
      'function(dat) {
         dat$AVG_SUGAR <- mean(dat$residual.sugar) 
         res <- dat[,c("alcohol", "residual.sugar", "AVG_SUGAR")]
      } ');
END;

CREATE OR REPLACE PACKAGE WhiteWinePkg AS
   TYPE cur IS REF CURSOR RETURN WHITE_WINE%ROWTYPE;
END WhiteWinePkg;

CREATE OR REPLACE FUNCTION My_GroupEval(
   inp_cur WhiteWinePkg.cur,
   par_cur SYS_REFCURSOR,
   out_qry VARCHAR2,
   grp_col VARCHAR2,
   exp_txt CLOB)
RETURN SYS.AnyDataSet
PIPELINED PARALLEL_ENABLE (PARTITION inp_cur BY HASH ("alcohol"))
CLUSTER inp_cur BY ("alcohol")
USING rqGroupEvalImpl;


SELECT *
FROM table(MY_GroupEval(
cursor(SELECT * FROM WHITE_WINE),
NULL,
'XML', 'alcohol', 'DEMO_GROUP_EVAL'));


SELECT *
FROM table(MY_GroupEval(
cursor(SELECT * FROM WHITE_WINE),
NULL,
'select 1 as "alcohol", 1 as "residual_sugar", 1 as "Avg_Sugar" from dual',
'alcohol', 'DEMO_GROUP_EVAL'));


-- Using the ORE rqRowEval() function
select *
from table(rqRowEval(cursor(select * from white_wine), 
                  cursor(select 1 as "ore.connect", 'DEMO_LM_DS' as "ds_name" from dual),
                  'select 1 as "alcohol", 1 as "PRED" from dual',
                  500,
                  'DEMO_LM_APPLY') );

 
                  
                  