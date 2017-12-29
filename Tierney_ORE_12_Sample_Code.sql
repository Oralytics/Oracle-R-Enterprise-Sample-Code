#
# Oracle R Enterprise Book - by Brendan Tierney
#    Published by : McGraw-Hill / Oracle Press
#
# Chapter 12 : Using ORE with Oracle Data Mining : SQL file
#

-- create the settings table for a Decision Tree modelCREATE TABLE demo_class_dt_settings ( setting_name  VARCHAR2(30),  setting_value VARCHAR2(4000));-- insert the settings records for a Decision Tree-- Decision Tree algorithm. By Default Naive Bayes is used for classification-- ADP is turned on. By default ADP is turned off.BEGIN  INSERT INTO demo_class_dt_settings (setting_name, setting_value)  values (dbms_data_mining.algo_name, dbms_data_mining.algo_decision_tree);	  INSERT INTO demo_class_dt_settings (setting_name, setting_value)  VALUES (dbms_data_mining.prep_auto,dbms_data_mining.prep_auto_on);END;BEGIN    DBMS_DATA_MINING.CREATE_MODEL(       model_name 			=> 'DEMO_CLASS_DT_MODEL',       mining_function 		=> dbms_data_mining.classification,       data_table_name 		=> 'MINING_DATA_READY_V',       case_id_column_name 	=> 'cust_id',       target_column_name 	=> 'affinity_card',       settings_table_name 	=> 'demo_class_dt_settings'); END;
SELECT cust_id,        PREDICTION(DEMO_CLASS_DT_MODEL USING *) Predicted_Value,       PREDICTION_PROBABILITY(DEMO_CLASS_DT_MODEL USING *) ProbFROM   mining_data_apply_vFETCH first 8 rows only;

-— create the model create R script
BEGIN
   --sys.rqScriptDrop(‘DT_RDEMO_BUILD_CLASSIFICATION’);
   sys.rqScriptCreate('DT_RDEMO_BUILD_CLASSIFICATION',
      'function(dat) {
         require(rpart)
         set.seed(1234)
         mod <- rpart(AFFINITY_CARD ~ ., method=“class”, data=dat)
         mod
      } ');
END;

-— DT model scoring R script
BEGIN
   --sys.rqScriptDrop(‘DT_RDEMO_SCORE_CLASSIFICATION’);
   sys.rqScriptCreate('DT_RDEMO_SCORE_CLASSIFICATION',
      'function(mod, dat) {
         require(rpart)
         res <- data.frame(predict(mod, newdata=dat, type = “prob”))
         names(res) <- c(“0”, “1”)
         res
      } ');
END;


-— DT model Weight Function R script
BEGIN
   --sys.rqScriptDrop(‘DT_RDEMO_WEIGHT_CLASSIFICATION’);
   sys.rqScriptCreate('DT_RDEMO_WEIGHT_CLASSIFICATION',
      'function(mod, dat, clas) {
         require(rpart)

         v0 <- as.data.frame(predict(mod, newdata=dat, type=“prob”))
         res <- data.frame(lapply(seq_along(dat),
         function(x, dat) {
         if(is.numeric(dat[[x]])) dat[.x] <- as.numeric(NA)
         else dat[,x] <- as.factor(NA)
         vv <- as.data.frame(predict(mod, newdata = dat, type = “prob”))
         v0[[clas]] / vv[[clas]]}, dat = dat))
         names(res) <- names(dat)
         res
      } ');
END;

-— DT model scoring R script
BEGIN
   --sys.rqScriptDrop(‘DT_RDEMO_DETAILS_CLASSIFICATION’);
   sys.rqScriptCreate('DT_RDEMO_DETAILS_CLASSIFICATION',
      'function(object, x) {
         mod.frm <- object$frame
         data.frame(node = row.names(mod.rm), split=mod.frm$var, n - mod.drm$n, ln = mod.frm$yval2[,2], rn = mod.frm$yval2[,3])
      } ');
END;
