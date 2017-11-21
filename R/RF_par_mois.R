#AZNAGUE Abdessamad
#21 Novembre 2017
#RF par mois

library(hydroGOF)
library(h2o)
library(randomForest)


#Préparation du train
databigg <- read_delim("C:/Users/abdes/Desktop/Challenge2018/Challenge2018/R/data_meteo/data_agregated.csv", 
                       ";", escape_double = FALSE, trim_ws = TRUE)
databigg <- databigg[,-1]
databigg = data.frame(databigg)
databigg$ech <- as.factor(databigg$ech)
databigg$insee <- as.factor(databigg$insee)
databigg$date <- as.Date(databigg$date)
databigg$mois <- as.factor(databigg$mois)
databigg$ddH10_rose4 <- as.factor(databigg$ddH10_rose4)
databig <- databigg

#Préparation du test
dftest <- read_delim("C:/Users/abdes/Desktop/Challenge2018/Challenge2018/R/data_meteo/test.csv", 
                     ";", escape_double = FALSE, trim_ws = TRUE)
dftest = data.frame(dftest)
dftest$ech <- as.factor(dftest$ech)
dftest$insee <- as.factor(dftest$insee)
dftest$date <- as.Date(dftest$date, format = "%d/%m/%y")
dftest$mois <- as.factor(dftest$mois)
dftest$tH2_obs <- as.numeric(dftest$tH2_obs)
dftest$ddH10_rose4 <- as.factor(dftest$ddH10_rose4)

#Boucle randomForest par mois
table(databig$mois)
table(dftest$mois)
mois <- c("mai", "juin", "juillet", "août", "septembre", "octobre", "novembre")

#Hold out

RMSE <- rep(100,8)

for(m in 1:7){
  if(m==8) out = c(1,9:12,20,31) else out = c(1,31)
  df <- databig[databig$mois==mois[m],-out]
  df <- df[complete.cases(df),]
  set.seed(123456)
  n <- nrow(df)
  ind.app <- sample(n, n*0.7)
  dapp <- df[ind.app, ]
  dtest <- df[-ind.app, ]
  mod <- randomForest(tH2_obs~., data = dapp)
  prev <- predict(mod, newdata = dtest, type = "response")
  RMSE[m] = rmse(prev, dtest$tH2_obs)
  
  #test <- dftest[dftest$mois==mois[m],-out]
  #prev <- predict(mod, newdata = test, type = "response")
  
  #for (i in 1:nrow(test)){
  #  dftest[dftest$mois==mois[m],]$tH2_obs[i] = prev[i]
  #}
}

#1.0275819   1.0634957   1.0814847   1.0046145   0.9300296   1.0699415   1.0350548 100.0000000

#Boucle prédiction

for(m in 1:7){
  if(m==8) out = c(1,9:12,20,31) else out = c(1,31)
  df <- databig[databig$mois==mois[m],-out]
  df <- df[complete.cases(df),]
  mod <- randomForest(tH2_obs~., data = df)
  
  test <- dftest[dftest$mois==mois[m],-out]
  prev <- predict(mod, newdata = test, type = "response")
  
  for (i in 1:nrow(test)){
    dftest[dftest$mois==mois[m],]$tH2_obs[i] = prev[i]
  }
}
