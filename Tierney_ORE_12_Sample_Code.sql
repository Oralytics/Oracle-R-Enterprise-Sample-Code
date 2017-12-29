#
# Oracle R Enterprise Book - by Brendan Tierney
#    Published by : McGraw-Hill / Oracle Press
#
# Chapter 12 : Using ORE with Oracle Data Mining : SQL file
#

-- create the settings table for a Decision Tree model
SELECT cust_id, 

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