

####################################################
########### DEEP LEARNING 2e test ##################


#### chargement package ####

library(h2o)
library(dplyr)

#setwd("D:/ben/master2/Defi_BIGDATA/Challenge2018/R")

#### fonction utiles ####

fac=function(test){
    test$ech <- as.factor(test$ech)
    test$insee <- as.factor(test$insee)
    test$date <- as.factor(test$date)
    test$mois <- as.factor(test$mois)
    test$ddH10_rose4 <- as.factor(test$ddH10_rose4)
    test
  }

test=read.csv('R/data_meteo/test.csv',sep=';',dec=',',header=T,stringsAsFactors = FALSE,encoding = "UTF-8")
test=fac(test)
test=test%>%select(-flvis1SOL0)


#### chargement donnees ####

data_agg=read.csv('R/data_meteo/data_agregated.csv',sep=';',dec='.',header=T,stringsAsFactors = FALSE,encoding = "UTF-8")
data_agg=fac(data_agg)

data_agg=data_agg%>%select(-X)%>%select(-flvis1SOL0)
data_agg=na.omit(data_agg)


##### deepL ####

var_cib='tH2_obs'
var_expl=setdiff(names(data_agg),var_cib)


insee=unique(as.vector(data_agg$insee))


h2o.init(nthreads = -1)
l_mod=c()
#insee2=c("31069001","33281001","35281001","59343001","67124001","75114001")
for (ville in insee){
  # preparation
  data=data_agg%>%filter(insee==ville)
  sample.ind <- sample(2,nrow(data),replace = T,prob = c(0.7,0.4))
  data.train <- data[sample.ind==1,]
  data.val <- data[sample.ind==2,]
  # mise au format h2o
  data_train <- as.h2o(data.train, destination_frame="data_train")
  data_valid=as.h2o(data.val,destination_frame = "data_valid")
  # Opti des param
  hyper_params <- list(
    activation=c("Rectifier","Tanh","Maxout","RectifierWithDropout","TanhWithDropout","MaxoutWithDropout"),
    hidden=list(c(20,20),c(50,50),c(30,30,30),c(25,25,25,25)),
    input_dropout_ratio=c(0,0.05),
    l1=seq(0,1e-4,1e-6),
    l2=seq(0,1e-4,1e-6)
  )
  #hyper_params
  ## Stop once the top 5 models are within 1% of each other (i.e., the windowed average varies less than 1%)
  search_criteria = list(strategy = "RandomDiscrete", max_runtime_secs = 360, max_models = 100, seed=1234567, stopping_rounds=5, stopping_tolerance=1e-2)
  dl_random_grid <- h2o.grid(
    algorithm="deeplearning",
    grid_id = "dl_grid_random",
    training_frame=data_train,
    validation_frame=data_valid, 
    x=var_expl, 
    y=var_cib,
    epochs=3,
    stopping_metric="RMSE",
    stopping_tolerance=1e-3,        ## stop when RMSE does not improve by >=0.1% for 2 scoring events
    stopping_rounds=2,
    score_validation_samples=1000, ## downsample validation set for faster scoring
    score_duty_cycle=0.025,         ## don't score more than 2.5% of the wall time
    max_w2=10,                      ## can help improve stability for Rectifier
    hyper_params = hyper_params,
    search_criteria = search_criteria
  )                                
  grid <- h2o.getGrid("dl_grid_random",sort_by="RMSE",decreasing=FALSE)
  grid
  grid@summary_table[1,]
  best_model <- h2o.getModel(grid@model_ids[[1]]) ## model with lowest RMSE
  l_mod=c(l_mod,best_model)
  # Write to the test file
  test1=test%>%filter(insee==ville)
  test1_h2=as.h2o(test1,destination_frame = "test1_h2")
  pred1=predict(best_model,newdata=test1_h2,type='response')
  pred1=as.vector(pred1)
  test1$th2_obs=pred1
  write.csv2(test1,paste(ville,'.csv',sep=''))
}







