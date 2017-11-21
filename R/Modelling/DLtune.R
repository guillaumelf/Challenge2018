#ALLEAU  20/11/2017
#h2o Deep learning avec coord sans na sans 


library(h2o)
library(readr)
library(dplyr)

source(file="R/fonction.R", encoding ="UTF-8")

### importation

test=read.csv('R/modif/test_WNADL.csv',sep=',',dec='.',header=T,stringsAsFactors = FALSE,encoding = "UTF-8")
test$ech <- as.factor(test$ech)
test$insee <- as.factor(test$insee)
test$ddH10_rose4 <- as.factor(test$ddH10_rose4)
dftest=test%>%select(-c(X,X.1))


data_agg=read.csv('R/modif/data_agg_gui.csv',sep=',',dec='.',header=T,stringsAsFactors = FALSE,encoding = "UTF-8")
data_agg=fac(data_agg)
databig=data_agg%>%select(-c(X,date,mois))

### PARTIE 1 

# chargement package
library(h2o)
library('stringr')


h2oServer <-h2o.init(nthreads = 1) # a changer selon la machine !!!
h2o.removeAll() # nettoie la memoire, au cas ou

# chargement donnees 


df <- as.h2o(databig)

splits <- h2o.splitFrame(df, 0.95, seed=1234)
train_hex  <- h2o.assign(splits[[1]], "train_hex") # 95%
test_hex  <- h2o.assign(splits[[2]], "test_hex")

### PARTIE 2

# fonction pour effectuer test auto
response <- "tH2_obs"
predictors <- setdiff(names(df), response)

workdir="/R/DL_resu" # PENSEZ A LE CHANGER !!!

score_test_set=T

run <- function(extra_params) {
  str(extra_params)
  print("Training.")
  model <- do.call(h2o.deeplearning, modifyList(list(x=predictors, y=response,
                                                     training_frame=train_hex, model_id="dlmodel"), extra_params))
  sampleshist <- model@model$scoring_history$samples
  samples <- sampleshist[length(sampleshist)]
  time <- model@model$run_time/1000
  print(paste0("training samples: ", samples))
  print(paste0("training time   : ", time, " seconds"))
  print(paste0("training speed  : ", samples/time, " samples/second"))
  
  if (score_test_set) {
    print("Scoring on test set.")
    test_error <- h2o.rmse(model)
    print(paste0("test set error  : ", test_error))
  } else {
    test_error <- 1.0
  }
  h2o.rm("dlmodel")
  c(paste(names(extra_params), extra_params, sep = "=", collapse=" "), 
    samples, sprintf("%.3f", time), 
    sprintf("%.3f", samples/time), sprintf("%.3f", test_error))
}

writecsv <- function(results, file) {
  table <- matrix(unlist(results), ncol = 5, byrow = TRUE)
  colnames(table) <- c("parameters", "training samples",
                       "training time", "training speed", "test set error")
  write.csv2(table, file.path(workdir,file))
}


### PREMIERE ETUDE

EPOCHS=100 

args <- list(
  list(hidden=c(256),            epochs=EPOCHS,validation_frame=test_hex),
  list(hidden=c(512),            epochs=EPOCHS,validation_frame=test_hex),
  list(hidden=c(1024),           epochs=EPOCHS,validation_frame=test_hex),
  list(hidden=c(64,64),          epochs=EPOCHS,validation_frame=test_hex),
  list(hidden=c(128,128),        epochs=EPOCHS,validation_frame=test_hex),
  list(hidden=c(256,256),        epochs=EPOCHS,validation_frame=test_hex),
  list(hidden=c(512,512),        epochs=EPOCHS,validation_frame=test_hex),
  list(hidden=c(1024,1024),      epochs=EPOCHS,validation_frame=test_hex),
  list(hidden=c(64,64,64),       epochs=EPOCHS,validation_frame=test_hex),
  list(hidden=c(128,128,128),    epochs=EPOCHS,validation_frame=test_hex),
  list(hidden=c(256,256,256),    epochs=EPOCHS,validation_frame=test_hex),
  list(hidden=c(512,512,512),    epochs=EPOCHS,validation_frame=test_hex),
  list(hidden=c(1024,1024,1024), epochs=EPOCHS,validation_frame=test_hex)
)

#t1=run(args[1])
writecsv(lapply(args, run), "network_topology.csv")



## fermeture h2o server
h2o.shutdown()
















