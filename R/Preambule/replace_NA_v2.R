#############################################################
#### Remplacement des NA dans les fichiers train et test ####
#############################################################

# Librairies utiles

library(data.table)
library(ggplot2)
library(hydroGOF)

# Fonctions utiles

fac=function(test){
  test$ech <- as.factor(test$ech)
  test$insee <- as.factor(test$insee)
  test$mois <- as.factor(test$mois)
  test$ddH10_rose4 <- as.factor(test$ddH10_rose4)
  test
}

sum_na <- function(x){
  return(sum(is.na(x)))
}

################
# Fichier test #
################

test <- data.table(read.csv("Python/Pre-processing/test_sep/31069001.csv",
                            header = TRUE,
                            sep = ";",
                            dec = ".",
                            stringsAsFactors = TRUE,
                            encoding = "UTF-8"))[,-1]

dec <- test[date == "2016-12-06"]

ggplot(dec)+aes(x=ech,y=flir1SOL0)+geom_line(col="blue")+
  labs(title = "")+
  theme(plot.title = element_text(hjust = 0.5))

ggplot(dec)+aes(x=ech,y=fllat1SOL0)+geom_line(col="blue")+
  labs(title = "")+
  theme(plot.title = element_text(hjust = 0.5))

ggplot(dec)+aes(x=ech,y=flsen1SOL0)+geom_line(col="blue")+
  labs(title = "")+
  theme(plot.title = element_text(hjust = 0.5))

ggplot(dec)+aes(x=ech,y=flvis1SOL0)+geom_line(col="blue")+
  labs(title = "")+
  theme(plot.title = element_text(hjust = 0.5))

# On va remplacer pour chaque fichier les NA du mois de decembre échéance 1 par les valeurs de l'echeance 2 du meme mois

path <- "Python/Pre-processing/test_sep"
for (file in list.files(path)){
  chemin <- paste0("Python/Pre-processing/test_sep/",file)
  test <- data.table(read.csv(chemin,
                              header = TRUE,
                              sep = ";",
                              dec = ".",
                              stringsAsFactors = TRUE,
                              encoding = "UTF-8"))[,-1]
  test[57:70,]$flir1SOL0 <- test[141:154,]$flir1SOL0
  test[57:70,]$fllat1SOL0 <- test[141:154,]$fllat1SOL0
  test[57:70,]$flsen1SOL0 <- test[141:154,]$flsen1SOL0
  test[57:70,]$flvis1SOL0 <- test[141:154,]$flvis1SOL0
  destination <- paste0("Python/Pre-processing/test_sep_NAfilled/",file)
  write.csv2(test,destination, sep = ";")
}

#################
# Fichier train #
#################

train <- data.table(read.csv("R/data_meteo/data_agregated.csv",
                             header = TRUE,
                             sep = ";",
                             dec = ".",
                             stringsAsFactors = TRUE,
                             encoding = "UTF-8"))[,-1]
train <- fac(train)
sapply(train,class)

# On separe le train en 2 tables pour nos tests : une table avec les lignes completes et celles contenant toutes les
# lignes avec des NAs

train_comp <- na.omit(train)
missing <- apply(train,MARGIN=1,sum_na)
train[, missing := missing]
missing_val <- train[missing >= 1][, missing := NULL]
train[, missing := NULL]

# On ne va utiliser que le fichier complet pour effectuer nos prédictions
# L'objectif va etre d'utiliser plusieurs méthodes et d'en estimer le risque par validation croisée Hold-Out,
# puis de comparer les risques.

indapp <- sample(1:nrow(train_comp), (2/3)*nrow(train_comp), replace=FALSE)
dapp <- data.frame(train_comp[indapp,])
dtest <- data.frame(train_comp[-indapp,])

# Toutes les variables quanti (mais pas les quali par contre) ont des NAs. On les extrait

quanti <- names(train)[sapply(train,class)!="factor"]

# Import du fichier de résultats construit sur python

res <- read.csv("Python/Pre-processing/NA_imputation_methods_results.csv",
                                    header = TRUE,
                                    sep = ";",
                                    dec = ".",
                                    stringsAsFactors = TRUE,
                                    encoding = "UTF-8")

# Test du décalage temporel. On remet le fichier en ordre

train[, c("date","ech") := .(as.IDate(date),as.numeric(ech))]
train <- train[order(date,ech)]
for (x in quanti){
  new_df <- train[, c(paste0("new_",x)) := .(shift(get(x), n = 7, type = "lead")), by = .(date)]
}

new_df <- na.omit(new_df)
indtest <- sample(1:nrow(new_df), nrow(dtest), replace=FALSE)
new_data <- new_df[indtest,]
original <- new_data[,c(3:6,8:29)]
pred <- new_data[,c(32:57)]

res_temp <- c("Decalage temporel")
for (j in 1:ncol(original)){
  res_temp <- c(res_temp,rmse(sim = pred[,j,with=FALSE], obs = original[,j,with=FALSE])[[1]])
}

res <- rbind(res,res_temp)
destination <- "Python/Pre-processing/NA_imputation_methods_results.csv"
write.csv2(res,destination, sep = ";")
