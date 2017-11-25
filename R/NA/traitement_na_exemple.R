########################################################################
###### Exemple de traitement des valeurs manquantes par wikistat #######
########################################################################

###############################
### 2.1 Lecture des données ###
###############################

# lecture des données
dat=read.table("Paris2005.dat")

# Les données ne sont visiblement pas gaussiennes
boxplot(dat)
hist(dat[,1])
hist(dat[,50])

# Passage au log pour s’en approcher
dat=log(dat+1)
# Vérification visuelle
boxplot(dat)
hist(dat[,1])
hist(dat[,50])

##########################################
### 2.2 Création de données manquantes ###
##########################################

# initialisation du générateur
set.seed(42)
# Ratio de données manquantes
test.ratio=0.1
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
                   err.missForest,err.amelia),ylim=c(0,4))

###################################
### 2.5 Robustesse des méthodes ###
###################################

# de 10 à 80% de données manquantes
TEST.RATIO=seq(0.1,0.8,by=0.1)
# initialisation des matrices d’erreur
err.amelia=matrix(NA,nrow=length(TEST.RATIO),
                  ncol=280)
err.mf=matrix(NA,nrow=length(TEST.RATIO),
              ncol=280)
err.svd=matrix(NA,nrow=length(TEST.RATIO),
               ncol=280)
tmp=1
for (test.ratio in TEST.RATIO){
  IND=which(!is.na(dat),arr.ind=TRUE)
  ntest=ceiling(dim(dat)[1]*test.ratio)
  ind.test=IND[sample(1:dim(IND)[1],ntest),]
  dat.test=dat[ind.test]
  dat.train=dat
  dat.train[ind.test]=NA
  dat.amelia=amelia(dat.train,m=1)$imputations$imp1
  err.amelia[tmp,1:length(ind.test[,2])]=abs(
    dat.test-dat.amelia[ind.test])
  dat.SVD=impute.svd(dat.train,k=3,maxiter=1000)$x
  err.svd[tmp,1:length(ind.test[,2])]=abs(dat.test
                                          -dat.SVD[ind.test])
  dat.mf<-missForest(dat.train, maxiter=10,
                     ntree = 200, variablewise = TRUE)$ximp
  err.mf[tmp,1:length(ind.test[,2])]=abs(
    dat.test-dat.mf[ind.test])
  tmp=tmp+1
}
# Affichage des erreurs
# ratio de données manquantes en abscisse

boxplot(data.frame(t(err.amelia)),
        na.action=na.omit,ylim=c(0,0.2),
        xlab="ratio de données manquantes",
        ylab="erreur AmeliaII",
        main="Erreurs de complétion sur l’échantillon
test par AmeliaII")
boxplot(data.frame(t(err.svd)),na.action=na.omit,
        ylim=c(0,0.3),xlab="ratio de données manquantes",
        ylab="erreur SVD",
        main="Erreurs de complétion sur l’échantillon
test par SVD")
boxplot(data.frame(t(err.mf)),na.action=na.omit,
        ylim=c(0,0.3),xlab="ratio de données manquantes",
        ylab="erreur missForest",
        main="Erreurs de complétion sur l’échantillon
test par missForest")
