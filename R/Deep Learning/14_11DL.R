#ALLEAU  14/11/2017
#h2o Deep learning avec coord sans na sans 

library(hydroGOF)
library(h2o)
library(readr)
library(dplyr)


#### fonction utiles ####

fac=function(test){
  test$ech <- as.factor(test$ech)
  test$insee <- as.factor(test$insee)
  test$date <- as.factor(test$date)
  test$mois <- as.factor(test$mois)
  test$ddH10_rose4 <- as.factor(test$ddH10_rose4)
  test
}


#### importation ####

test=read.csv('R/Deep Learning/test_gui.csv',sep=',',dec='.',header=T,stringsAsFactors = FALSE,encoding = "UTF-8")
test=fac(test)
dftest=test%>%select(-c(X,X.1))


data_agg=read.csv('R/Deep Learning/data_agg_gui.csv',sep=',',dec='.',header=T,stringsAsFactors = FALSE,encoding = "UTF-8")
data_agg=fac(data_agg)
databig=data_agg%>%select(-X)


#### Let's go ####


h2o.init(nthreads = 3)
df <- as.h2o(databig)

splits <- h2o.splitFrame(df, 0.88, seed=1234)
train  <- h2o.assign(splits[[1]], "train.hex") # 60%
valid  <- h2o.assign(splits[[2]], "valid.hex") # 20%
#test   <- h2o.assign(splits[[3]], "test.hex")  # 20%
dim(valid)

# Specify the response and predictor columns
response <- "tH2_obs"
predictors <- setdiff(names(df), response)

hyper_params <- list(
  hidden=list(c(32,32,32),c(64,64)),
  input_dropout_ratio=c(0,0.05),
  rate=c(0.01,0.02),
  rate_annealing=c(1e-8,1e-7,1e-6)
)
hyper_params
grid <- h2o.grid(
  algorithm="deeplearning",
  grid_id="dl_grid", 
  training_frame=train,
  validation_frame=valid, 
  x=predictors, 
  y=response,
  epochs=60,
  stopping_metric="RMSE",
  stopping_tolerance=1e-2,        ## stop when misclassification does not improve by >=1% for 2 scoring events
  stopping_rounds=2,
  score_validation_samples=10000, ## downsample validation set for faster scoring
  score_duty_cycle=0.025,         ## don't score more than 2.5% of the wall time
  adaptive_rate=F,                ## manually tuned learning rate
  momentum_start=0.5,             ## manually tuned momentum
  momentum_stable=0.9, 
  momentum_ramp=1e7, 
  l1=1e-5,
  l2=1e-5,
  activation=c("Rectifier"),
  max_w2=10,                      ## can help improve stability for Rectifier
  hyper_params=hyper_params
)
grid


grid <- h2o.getGrid("dl_grid",sort_by="RMSE",decreasing=FALSE)
grid

## To see what other "sort_by" criteria are allowed
#grid <- h2o.getGrid("dl_grid",sort_by="wrong_thing",decreasing=FALSE)


## Find the best model and its full set of parameters
grid@summary_table[1,]
best_model <- h2o.getModel(grid@model_ids[[1]])
best_model
plot(best_model)


#print(best_model@allparameters)
print(h2o.performance(best_model, valid=T))



# PREDICTION

#Prédiction

dfprev <- as.h2o(dftest)
preds <- h2o.predict(best_model, newdata = dfprev)
prev <- as.vector(preds$predict)
sum(is.na(prev))

dftest$TH2_obs=prev

write.csv(dftest, "resu.csv")
h2o.shutdown()
