#
# Oracle R Enterprise Book - by Brendan Tierney
#    Published by : McGraw-Hill / Oracle Press
#
# Chapter 9 : Creating ORE Scripts : SQL file
#

-- Create a user defined R script
BEGIN 
   sys.rqScriptCreate('DEMO_LM_APPLY', 
                   'function(dat, ds_name) { 
         ore.load(ds_name) 
         pre <- predict(mod, newdata=dat, supplemental.cols="alcohol")          
         res <- cbind(dat, PRED=pre) 
         res <- res[,c("alcohol", "PRED")] 
      } '); 
END;


-- Create a global R Script
BEGIN sys.rqScriptDrop('DEMO_LM_APPLY'); END;
BEGIN 
   sys.rqScriptCreate('DEMO_LM_APPLY', 
                   'function(dat, ds_name) { 
         ore.load(ds_name) 
         pre <- predict(mod, newdata=dat, supplemental.cols="alcohol")          
         res <- cbind(dat, PRED=pre) 
         res <- res[,c("alcohol", "PRED")] 
      } ', TRUE); 
END;

-- Run the apply script on the new data 
select * 
  from table(rqTableEval(cursor(select * from white_wine),                    
                         cursor(select 1 as "ore.connect", 'DEMO_LM_DS' as "ds_name" from dual),                   
                         'select 1 as "alcohol", 1 as "PRED" from dual', 
                         'DEMO_LM_APPLY') );
                         
-- Recreate an ORE Script and make it private.
BEGIN 
   sys.rqScriptCreate('DEMO_LM_APPLY', 
                   'function(dat, ds_name) { 
         ore.load(ds_name) 
         pre <- predict(mod, newdata=dat, supplemental.cols="alcohol")          
         res <- cbind(dat, PRED=pre) 
         res <- res[,c("alcohol", "PRED")] 
      } ', FALSE, TRUE); 
END;


-- Run the script using the rqTableEval function
select *
from table(rqTableEval(cursor(select * from white_wine), 
                  cursor(select 1 as "ore.connect", 'DEMO_LM_DS' as "ds_name" from dual),
                  'select 1 as "alcohol", 1 as "PRED" from dual',
                  'DEMO_LM_APPLY') );


--
-- Using the sys.rqScriptDrop function to remove an ORE script
BEGIN
   sys.rqScriptDrop('DEMO_LM_APPLY'); 
END;

--
-- Grant the DMUSER user access to the DEMO_LM_APPLY ORE script
BEGIN
   rqGrant('DEMO_LM_APPLY', 'rqscript', 'DMUSER'); 
END;


--
-- Grant the DMUSER user access to the DEMO_LM_APPLY ORE script
BEGIN
   rqRevoke('DEMO_LM_APPLY', 'rqscript', 'DMUSER'); 
END;


-- 
-- Viewing the scripts in the ORE script repository
--
select * from all_rq_scripts;
select * from user_rq_scripts;
select * from user_rq_script_privs;
select * from sys.rq_scripts;
select * from sys.rq_scripts where owner='RQSYS';


