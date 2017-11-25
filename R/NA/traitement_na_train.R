#################################################################
##### Imputation des NA dans les fichiers train par station #####
#################################################################

############################
### 1. Fonctions locales ###
############################

sum_na <- function(x){
  return(sum(is.na(x)))
}

fac=function(test){
  test$date <- as.factor(test$date)
  test$ech <- as.factor(test$ech)
  test$insee <- as.factor(test$insee)
  test$mois <- as.factor(test$mois)
  test$ddH10_rose4 <- as.factor(test$ddH10_rose4)
  test
}
###############################
### 2.1 Lecture des données ###
###############################

# lecture des données
library(data.table)
path <- "Python/Pre-processing/data_agg_sep"
i <- 1
for (file in list.files(path)){
  chemin <- paste0("Python/Pre-processing/data_agg_sep/",file)
  assign(paste0("train_",i),fac(data.table(read.csv(chemin,
                              header = TRUE,
                              sep = ";",
                              dec = ".",
                              stringsAsFactors = TRUE,
                              encoding = "UTF-8"))[,-c(1,2)]))
  i = i+1
}

# Résumé des valeurs manquantes par fichier
villes <- c("Toulouse","Bordeaux","Rennes","Lille","Nice","Strasbourg","Paris")
NAs <- c()
for (i in 1:7){
  NAs <- c(NAs,sum(is.na(get(paste0("train_",i)))))
}
# Il en manque autant dans chaque fichier : on va donc faire nos essais sur un seul fichier
sapply(train_1,sum_na)
quanti <- names(train_1)[sapply(train_1,class)=="numeric"]
# On ne va conserver que les lignes entières pour effectuer le test fictif
dat <- as.data.frame(na.omit(train_1[,quanti,with=FALSE]))
ind <- sample(1:nrow(dat),2000,replace = FALSE)
dat <- dat[ind,]
# On peut maintenant lancer la procédure

##########################################
### 2.2 Création de données manquantes ###
##########################################

# initialisation du générateur
set.seed(42)
# Ratio de données manquantes
test.ratio=0.2
# Indices de l’échantillon test
IND=which(!is.na(dat),arr.ind=TRUE)
ntest=ceiling(dim(dat)[1]*test.ratio)
ind.test=IND[sample(1:dim(IND)[1],ntest),]
# Création des données manquantes
dat.test=dat[ind.test]
dat.train=dat
dat.train[ind.test]=NA

######################
### 2.3 Imputation ###
######################

##############
# 2.3.1 LOCF #
##############

# chargement de la bibliothèque
library(zoo)

dat.locf=na.locf(dat.train,na.rm=FALSE)
dat.locf=na.locf(dat.locf,na.rm=FALSE,
                 fromLast=TRUE)
# calcul de l’erreur
err.locf=abs(dat.test-dat.locf[ind.test])

########################
# 2.3.2 Par la moyenne #
########################

# chargement de la bibliothèque
library(Hmisc)
dat.moy=impute(dat.train, fun=mean)
err.moy=abs(dat.test-as.matrix(dat.moy)[ind.test])

########################
# 2.3.2 Par la médiane #
########################

med=apply(dat.train,1,median,na.rm=TRUE)
dat.med=dat.train
ind.na=which(is.na(dat.med),arr.ind=TRUE)
dat.med[ind.na]=med[ind.na[,1]]
err.med=abs(dat.test-dat.med[ind.test])

####################################
# 2.3.4 k plus proches voisins kNN #
####################################

# chargement de la bibliothèque
library(VIM)
dat.kNN=kNN(dat.train, k=5, imp_var=FALSE)
err.kNN=abs(dat.test-dat.kNN[ind.test])

###############
# 2.3.5 LOESS #
###############

# chargement de la bibliothèque
library(locfit)
dat.imputed=rbind(colnames(dat.train),dat.train)
indices=1:nrow(dat.train)
dat.loess= apply(dat.imputed, 2, function(j) {
  predict(locfit(j[-1] ~ indices), indices)
})
err.loess=abs(dat.test-dat.loess[ind.test])

#############
# 2.3.6 SVD #
#############

# chargement de la bibliothèque
library(bcv)
dat.SVD=impute.svd(dat.train,k=3,maxiter=1000)$x
err.svd=abs(dat.test-dat.SVD[ind.test])

####################
# 2.3.7 missForest #
####################

# chargement de la bibliothèque
library(missForest)
dat.missForest<-missForest(dat.train,maxiter=10,
                           ntree = 200, variablewise = TRUE)$ximp
err.missForest=abs(dat.test-dat.missForest[ind.test])

##################
# 2.3.8 AmeliaII #
##################

# chargement de la bibliothèque
library(Amelia)
dat.amelia=amelia(dat.train,m=1)$imputations$imp1
err.amelia=abs(dat.test-dat.amelia[ind.test])

#####################################
### 2.4 Comparaison des résultats ###
#####################################

# Erreurs de complétion sur l’échantillon test
boxplot(data.frame(err.locf,err.moy,
                   err.med,err.kNN,err.loess,err.svd,
                   err.missForest,err.amelia),ylim=c(0,100))

