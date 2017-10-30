#Abdessamad AZNAGUE 25/10/2017
#RANDOM FOREST / Station


library(corrplot)
library(ggplot2)
library(hydroGOF)
library(dplyr)
library(kernlab)
library(caret)
library(randomForest)

#Préparation du jeu de données data_agregated

databigg <- read.csv("R/data_meteo/data_agregated.csv", 
                      ";", escape_double = FALSE, trim_ws = TRUE)
databigg <- databigg[,-1]
databigg = data.frame(databigg)

databigg$ech <- as.factor(databigg$ech)
databigg$insee <- as.factor(databigg$insee)
databigg$date <- as.factor(databigg$date)
databigg$mois <- as.factor(databigg$mois)
databigg$ddH10_rose4 <- as.factor(databigg$ddH10_rose4)

#Création d'une variable jour-mois qui pourrait être utile, mais pas utilisée au RF car trop
#de modalités
datevec <- databigg$date
datevec <- as.Date(datevec)
databigg$daymonth = as.factor(format(datevec, format = "%d - %m"))

databig <- databigg

#Importation et préparation du fichier test et préparation
test <- read_delim("C:/Users/abdes/Desktop/Challenge2018/Challenge2018/R/data_meteo/test.csv", 
                   ";", escape_double = FALSE, trim_ws = TRUE)
test = data.frame(test)

test$ech <- as.factor(test$ech)
test$insee <- as.factor(test$insee)
test$date <- as.factor(test$date)
test$mois <- as.factor(test$mois)
test$tH2_obs <- as.numeric(test$tH2_obs)
test$ddH10_rose4 <- as.factor(test$ddH10_rose4)
table(test$mois)
dim(test)

datevec <- test$date
datevec <- as.Date(datevec)
test$daymonth = as.factor(format(datevec, format = "%d - %m"))

######################################################################
#************** Boucle RandomForest par station **********************
######################################################################


#setwd("C:/Users/abdes/Desktop/Challenge2018/Prédiction")

insee <- levels(databig$insee)
df_station <- lapply (1:7, function(x) c())
dapp_station <- lapply (1:7, function(x) c())
dtest_station <- lapply (1:7, function(x) c())
modele <- lapply (1:7, function(x) c())
prev_modele <- lapply (1:7, function(x) c())
df_test_station <- lapply (1:7, function(x) c())
prev_test <- lapply (1:7, function(x) c())
somme_na_prev <- rep(999,7)
RMSE <- rep(999,7)

for (i in 1:7){
  #Extraction du dataframe de la station i, privé de certaines variables
  #qui possèdent des NA dans le fichier test (on pourra les remettre quand
  #on aura remplacé ces NA (rfImpute?)), + les variables insee, ech, date, mois et
  #jour-mois créée au début du script
  Out <- c(1,2,9:12,20,30,31,32)
  df_station[[i]] <- databig[databig$insee==insee[i],-Out]
  df_station[[i]] <- df_station[[i]][complete.cases(df_station[[i]]),]
  
  #Hold-Out 70%-30%
  set.seed(123456)
  n <- nrow(df_station[[i]])
  ind.app <- sample(n, n*0.7)
  dapp_station[[i]] <- df[ind.app, ]
  dtest_station[[i]] <- df[-ind.app, ]
  
  modele[[i]] <- randomForest(tH2_obs ~ ., data = dapp_station[[i]])
  
  #Modèle et prédiction
  prev_modele[[i]] <- predict(modele[[i]], newdata = dtest_station[[i]], type = "response")
  RMSE[i] = rmse(prev_modele[[i]], dtest_station[[i]]$tH2_obs)
  
  #Prédiction sur le jeu Test
  df_test_station[[i]] <- test[test$insee==insee[i],-Out]
  colnames(df_test_station)[colSums(is.na(df_test_station)) > 0]
  prev_test[[i]] <- predict(modele[[i]], newdata = df_test_station, type = "response")
  somme_na_prev[i] <- sum(is.na(prev_test[[i]]))
  write.csv(prev_test[[i]], paste("Station", i, ".csv", sep = ""))
  
  #Remplir les prévisions dans le fichier Test
  for (j in 1:nrow(prev_test[[i]])){
    test[test$insee==insee[i],]$tH2_obs[j] = prev_test[[i]][j]
  }
}
#################################################################
#RMSE hier : c(0.9772791, 1.064226, 1.040446, 1.009976, 0.9275015, 1.198078, 0.8888599)
mean(RMSE)
sum(is.na(test$tH2_obs)) #Zéro
write.csv(test$tH2_obs, "predictionsRF2510.csv")
#################################################################



##############################################################################
#************** Modèle RandomForest pour chaque station **********************
##############################################################################

#Intérêt : Pouvoir calibrer les paramètres pour chaque station pour améliorer les prévisions

df1 <- databig[databig$insee==insee[1],]
df1 = df1[,-c(1,2,9:12,20,30,31,32)]
df1 <- df1[complete.cases(df1),]
set.seed(123456)
n <- nrow(df1)
ind.app <- sample(n, n*0.7)
dapp1 <- df1[ind.app, ]
dtest1 <- df1[-ind.app, ]
mod1 <- randomForest(tH2_obs ~ ., data = dapp1)
prev1 <- predict(mod1, newdata = dtest1, type = "response")
rmse(prev1, dtest1$tH2_obs)

dftest1 <- test[test$insee==insee[1],]
dftest1 = dftest1[,-c(1,2,9:12,20,30,31,32)]
colnames(dftest1)[colSums(is.na(dftest1)) > 0]
dftest1$tH2_obs <- 0
prevtest1 <- predict(mod1, newdata = dftest1, type = "response")
sum(is.na(prevtest1))
write.csv(prevtest1, "S6088001.csv")

for (i in 1:nrow(prevtest1)){
  test[test$insee==insee[1],]$tH2_obs[i] = prevtest1[i]
}


#############################################################

df2 <- databig[databig$insee==insee[2],]
df2 = df2[,-c(1,2,9:12,20,31,32)]
df2 <- df2[complete.cases(df2),]
set.seed(123456)
n <- nrow(df2)
ind.app <- sample(n, n*0.7)
dapp2 <- df2[ind.app, ]
dtest2 <- df2[-ind.app, ]
mod2 <- randomForest(tH2_obs ~ ., data = dapp2)
prev2 <- predict(mod2, newdata = dtest2, type = "response")
rmse(prev2, dtest2$tH2_obs)

dftest2 <- test[test$insee==insee[2],]
dftest2 = dftest2[,-c(1,2,9:12,20,31,32)]
colnames(dftest2)[colSums(is.na(dftest2)) > 0]
prevtest2 <- predict(mod2, newdata = dftest2, type = "response")
sum(is.na(prevtest2))
write.csv(prevtest2, "S31069001.csv")

for (i in 1:nrow(prevtest2)){
  test[test$insee==insee[2],]$tH2_obs[i] = prevtest2[i]
}


#############################################################

df3 <- databig[databig$insee==insee[3],]
df3 = df3[,-c(1,2,9:12,20,30,31,32)]
df3 <- df3[complete.cases(df3),]
set.seed(123456)
n <- nrow(df3)
ind.app <- sample(n, n*0.7)
dapp3 <- df3[ind.app, ]
dtest3 <- df3[-ind.app, ]
mod3 <- randomForest(tH2_obs ~ ., data = dapp3)
prev3 <- predict(mod3, newdata = dtest3, type = "response")
rmse(prev3, dtest3$tH2_obs)

dftest3 <- test[test$insee==insee[3],]
dftest3 = dftest3[,-c(1,2,9:12,20,30,31,32)]
colnames(dftest3)[colSums(is.na(dftest3)) > 0]
prevtest3 <- predict(mod3, newdata = dftest3, type = "response")
sum(is.na(prevtest3))
write.csv(prevtest3, "S33281001.csv")

for (i in 1:nrow(prevtest3)){
  test[test$insee==insee[3],]$tH2_obs[i] = prevtest3[i]
}

#############################################################

df4 <- databig[databig$insee==insee[4],]
df4 = df4[,-c(1,2,9:12,20,30,31,32)]
df4 <- df4[complete.cases(df4),]
set.seed(123456)
n <- nrow(df4)
ind.app <- sample(n, n*0.7)
dapp4 <- df4[ind.app, ]
dtest4 <- df4[-ind.app, ]
mod4 <- randomForest(tH2_obs ~ ., data = dapp4)
prev4 <- predict(mod4, newdata = dtest4, type = "response")
rmse(prev4, dtest4$tH2_obs)

dftest4 <- test[test$insee==insee[4],]
dftest4 = dftest4[,-c(1,2,9:12,20,30,31,32)]
colnames(dftest4)[colSums(is.na(dftest4)) > 0]
prevtest4 <- predict(mod4, newdata = dftest4, type = "response")
sum(is.na(prevtest4))
write.csv(prevtest4, "S33281001.csv")

for (i in 1:nrow(prevtest4)){
  test[test$insee==insee[4],]$tH2_obs[i] = prevtest4[i]
}

#############################################################

df5 <- databig[databig$insee==insee[5],]
df5 = df5[,-c(1,2,9:12,20,30,31,32)]
df5 <- df5[complete.cases(df5),]
set.seed(123456)
n <- nrow(df5)
ind.app <- sample(n, n*0.7)
dapp5 <- df5[ind.app, ]
dtest5 <- df5[-ind.app, ]
mod5 <- randomForest(tH2_obs ~ ., data = dapp5)
prev5 <- predict(mod5, newdata = dtest5, type = "response")
rmse(prev5, dtest5$tH2_obs)

dftest5 <- test[test$insee==insee[5],]
dftest5 = dftest5[,-c(1,2,9:12,20,30,31,32)]
colnames(dftest5)[colSums(is.na(dftest5)) > 0]
prevtest5 <- predict(mod5, newdata = dftest5, type = "response")
sum(is.na(prevtest5))
write.csv(prevtest5, "S59343001.csv")

for (i in 1:nrow(prevtest5)){
  test[test$insee==insee[5],]$tH2_obs[i] = prevtest5[i]
}

#############################################################

df6 <- databig[databig$insee==insee[6],]
df6 = df6[,-c(1,2,9:12,20,30,31,32)]
df6 <- df6[complete.cases(df6),]
set.seed(123456)
n <- nrow(df6)
ind.app <- sample(n, n*0.7)
dapp6 <- df6[ind.app, ]
dtest6 <- df6[-ind.app, ]
mod6 <- randomForest(tH2_obs ~ ., data = dapp6)
prev6 <- predict(mod6, newdata = dtest6, type = "response")
rmse(prev6, dtest6$tH2_obs)

dftest6 <- test[test$insee==insee[6],]
dftest6 = dftest6[,-c(1,2,9:12,20,30,31,32)]
colnames(dftest6)[colSums(is.na(dftest6)) > 0]
prevtest6 <- predict(mod6, newdata = dftest6, type = "response")
sum(is.na(prevtest6))
write.csv(prevtest6, "S67124001.csv")

for (i in 1:nrow(prevtest6)){
  test[test$insee==insee[6],]$tH2_obs[i] = prevtest6[i]
}

#############################################################

df7 <- databig[databig$insee==insee[7],]
df7 = df7[,-c(1,2,9:12,20,30,31,32)]
df7 <- df7[complete.cases(df7),]
set.seed(123456)
n <- nrow(df7)
ind.app <- sample(n, n*0.7)
dapp7 <- df7[ind.app, ]
dtest7 <- df7[-ind.app, ]
mod7 <- randomForest(tH2_obs ~ ., data = dapp7)
prev7 <- predict(mod7, newdata = dtest7, type = "response")
rmse(prev7, dtest7$tH2_obs)

dftest7 <- test[test$insee==insee[7],]
dftest7 = dftest7[,-c(1,2,9:12,20,30,31,32)]
colnames(dftest7)[colSums(is.na(dftest7)) > 0]
prevtest7 <- predict(mod7, newdata = dftest7, type = "response")
sum(is.na(prevtest7))
write.csv(prevtest7, "S75114001.csv")

for (i in 1:nrow(prevtest7)){
  test[test$insee==insee[7],]$tH2_obs[i] = prevtest7[i]
}


