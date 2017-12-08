#################################################################
##### Imputation des NA dans les fichiers train par station #####
#################################################################

####################
### 0. Préambule ###
####################

res_na <- read.csv("Python/Pre-processing/NA_imputation_methods_results.csv",header=TRUE,sep=";",row.names="X")[,-1]
resume <- apply(res_na,MARGIN = 2,mean)
df <- data.frame(variable = names(res_na),error = resume)
library(ggplot2)
ggplot(df)+aes(x=variable,y=error)+geom_bar(stat="identity",fill="blue")+
  labs(title = "Erreur moyenne pour chaque variable")+
  theme(plot.title = element_text(hjust = 0.5))

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
dat <- as.data.frame(na.omit(train_1[,quanti[c(1,3:5,11:26)],with=FALSE]))
ind <- sample(1:nrow(dat),2000,replace = FALSE)
dat <- dat[ind,]
# On peut maintenant lancer la procédure

##########################################
### 2.2 Création de données manquantes ###
##########################################

# initialisation du générateur
set.seed(42)
# Ratio de données manquantes
test.ratio=0.5
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
dat.SVD=impute.svd(dat.train,k=3,maxiter=2000)$x
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
                   err.missForest,err.amelia),ylim=c(0,10), main = "Erreur en fonction de la méthode utilisée",col=c(2,1,3:9))

##############################
### 3. Imputation avec KNN ###
##############################

files = list.files(path)

# Puis sur les données test

path <- "Python/Pre-processing/test_sep_NAfilled"
i <- 1
for (file in list.files(path)){
  chemin <- paste0("Python/Pre-processing/test_sep_NAfilled/",file)
  assign(paste0("test_",i),fac(data.table(read.csv(chemin,
                                                   header = TRUE,
                                                   sep = ";",
                                                   dec = ",",
                                                   stringsAsFactors = TRUE,
                                                   encoding = "UTF-8"))[,-1]))
  i = i+1
}

new <- as.data.frame(test_1[,quanti[c(3:5,11:26)],with=FALSE])
dat.kNN=kNN(new, k=5, imp_var=FALSE)
test_1$ciwcH20 <- dat.kNN$ciwcH20
test_1$clwcH20 <- dat.kNN$clwcH20
test_1$ffH10 <- dat.kNN$ffH10
test_1$huH2 <- dat.kNN$huH2
test_1$iwcSOL0 <- dat.kNN$iwcSOL0
test_1$nbSOL0_HMoy <- dat.kNN$nbSOL0_HMoy
test_1$nH20 <- dat.kNN$nH20
test_1$ntSOL0_HMoy <- dat.kNN$ntSOL0_HMoy
test_1$pMER0 <- dat.kNN$pMER0
test_1$rr1SOL0 <- dat.kNN$rr1SOL0
test_1$rrH20 <- dat.kNN$rrH20
test_1$tH2 <- dat.kNN$tH2
test_1$tH2_VGrad_2.100 <- dat.kNN$tH2_VGrad_2.100
test_1$tH2_XGrad <- dat.kNN$tH2_XGrad
test_1$tH2_YGrad <- dat.kNN$tH2_YGrad
test_1$tpwHPA850 <- new$tpwHPA850
test_1$ux1H10 <- dat.kNN$ux1H10
test_1$vapcSOL0 <- dat.kNN$vapcSOL0
test_1$vx1H10 <- dat.kNN$vx1H10
write.csv(test_1,paste0("R/NA/test/",files[1]),row.names = FALSE,fileEncoding = "UTF-8")

new <- as.data.frame(test_2[,quanti[c(3:5,11:26)],with=FALSE])
dat.kNN=kNN(new, k=5, imp_var=FALSE)

test_2$ciwcH20 <- dat.kNN$ciwcH20
test_2$clwcH20 <- dat.kNN$clwcH20
test_2$ffH10 <- dat.kNN$ffH10
test_2$huH2 <- dat.kNN$huH2
test_2$iwcSOL0 <- dat.kNN$iwcSOL0
test_2$nbSOL0_HMoy <- dat.kNN$nbSOL0_HMoy
test_2train_2$ntSOL0_HMoy <- dat.kNN$ntSOL0_HMoy
test_2$pMER0 <- dat.kNN$pMER0
test_2$rr1SOL0 <- dat.kNN$rr1SOL0
test_2$rrH20 <- dat.kNN$rrH20
test_2$tH2 <- dat.kNN$tH2
test_2$tH2_VGrad_2.100 <- dat.kNN$tH2_VGrad_2.100
test_2$tH2_XGrad <- dat.kNN$tH2_XGrad
test_2$tH2_YGrad <- dat.kNN$tH2_YGrad
test_2$tpwHPA850 <- dat.kNN$tpwHPA850
test_2$ux1H10 <- dat.kNN$ux1H10
test_2$vapcSOL0 <- dat.kNN$vapcSOL0
test_2$vx1H10 <- dat.kNN$vx1H10
write.csv(test_2,paste0("R/NA/test/",files[2]),row.names = FALSE,fileEncoding = "utf-8")

new <- as.data.frame(test_3[,quanti[c(3:5,11:26)],with=FALSE])
dat.kNN=kNN(new, k=5, imp_var=FALSE)

test_3$ciwcH20 <- dat.kNN$ciwcH20
test_3$clwcH20 <- dat.kNN$clwcH20
test_3$ffH10 <- dat.kNN$ffH10
test_3$huH2 <- dat.kNN$huH2
test_3$iwcSOL0 <- dat.kNN$iwcSOL0
test_3$nbSOL0_HMoy <- dat.kNN$nbSOL0_HMoy
test_3$nH20 <- dat.kNN$nH20
test_3$ntSOL0_HMoy <- dat.kNN$ntSOL0_HMoy
test_3$pMER0 <- dat.kNN$pMER0
test_3$rr1SOL0 <- dat.kNN$rr1SOL0
test_3$rrH20 <- dat.kNN$rrH20
test_3$tH2 <- dat.kNN$tH2
test_3$tH2_VGrad_2.100 <- dat.kNN$tH2_VGrad_2.100
test_3$tH2_XGrad <- dat.kNN$tH2_XGrad
test_3$tH2_YGrad <- dat.kNN$tH2_YGrad
test_3$tpwHPA850 <- dat.kNN$tpwHPA850
test_3$ux1H10 <- dat.kNN$ux1H10
test_3$vapcSOL0 <- dat.kNN$vapcSOL0
test_3$vx1H10 <- dat.kNN$vx1H10
write.csv(test_3,paste0("R/NA/test/",files[3]),row.names = FALSE,fileEncoding = "utf-8")

new <- as.data.frame(test_4[,quanti[c(3:5,11:26)],with=FALSE])
dat.kNN=kNN(new, k=5, imp_var=FALSE)

test_4$ciwcH20 <- dat.kNN$ciwcH20
test_4$clwcH20 <- dat.kNN$clwcH20
test_4$ffH10 <- dat.kNN$ffH10
test_4$huH2 <- dat.kNN$huH2
test_4$iwcSOL0 <- dat.kNN$iwcSOL0
test_4$nbSOL0_HMoy <- dat.kNN$nbSOL0_HMoy
test_4$nH20 <- dat.kNN$nH20
test_4$ntSOL0_HMoy <- dat.kNN$ntSOL0_HMoy
test_4$pMER0 <- dat.kNN$pMER0
test_4$rr1SOL0 <- dat.kNN$rr1SOL0
test_4$rrH20 <- dat.kNN$rrH20
test_4$tH2 <- dat.kNN$tH2
test_4$tH2_VGrad_2.100 <- dat.kNN$tH2_VGrad_2.100
test_4$tH2_XGrad <- dat.kNN$tH2_XGrad
test_4$tH2_YGrad <- dat.kNN$tH2_YGrad
test_4$tpwHPA850 <- dat.kNN$tpwHPA850
test_4$ux1H10 <- dat.kNN$ux1H10
test_4$vapcSOL0 <- dat.kNN$vapcSOL0
test_4$vx1H10 <- dat.kNN$vx1H10
write.csv(test_4,paste0("R/NA/test/",files[4]),row.names = FALSE,fileEncoding = "utf-8")

new <- as.data.frame(test_5[,quanti[c(3:5,11:26)],with=FALSE])
dat.kNN=kNN(new, k=5, imp_var=FALSE)

test_5$ciwcH20 <- dat.kNN$ciwcH20
test_5$clwcH20 <- dat.kNN$clwcH20
test_5$ffH10 <- dat.kNN$ffH10
test_5$huH2 <- dat.kNN$huH2
test_5$iwcSOL0 <- dat.kNN$iwcSOL0
test_5$nbSOL0_HMoy <- dat.kNN$nbSOL0_HMoy
test_5$nH20 <- dat.kNN$nH20
test_5$ntSOL0_HMoy <- dat.kNN$ntSOL0_HMoy
test_5$pMER0 <- dat.kNN$pMER0
test_5$rr1SOL0 <- dat.kNN$rr1SOL0
test_5$rrH20 <- dat.kNN$rrH20
test_5$tH2 <- dat.kNN$tH2
test_5$tH2_VGrad_2.100 <- dat.kNN$tH2_VGrad_2.100
test_5$tH2_XGrad <- dat.kNN$tH2_XGrad
test_5$tH2_YGrad <- dat.kNN$tH2_YGrad
test_5$tpwHPA850 <- dat.kNN$tpwHPA850
test_5$ux1H10 <- dat.kNN$ux1H10
test_5$vapcSOL0 <- dat.kNN$vapcSOL0
test_5$vx1H10 <- dat.kNN$vx1H10
write.csv(test_5,paste0("R/NA/test/",files[5]), row.names = FALSE,fileEncoding = "utf-8")

new <- as.data.frame(test_6[,quanti[c(3:5,11:26)],with=FALSE])
dat.kNN=kNN(new, k=5, imp_var=FALSE)
test_6$tH2_obs <- dat.kNN$tH2_obs
test_6$ciwcH20 <- dat.kNN$ciwcH20
test_6$clwcH20 <- dat.kNN$clwcH20
test_6$ffH10 <- dat.kNN$ffH10
test_6$huH2 <- dat.kNN$huH2
test_6$iwcSOL0 <- dat.kNN$iwcSOL0
test_6$nbSOL0_HMoy <- dat.kNN$nbSOL0_HMoy
test_6$nH20 <- dat.kNN$nH20
test_6$ntSOL0_HMoy <- dat.kNN$ntSOL0_HMoy
test_6$pMER0 <- dat.kNN$pMER0
test_6$rr1SOL0 <- dat.kNN$rr1SOL0
test_6$rrH20 <- dat.kNN$rrH20
test_6$tH2 <- dat.kNN$tH2
test_6$tH2_VGrad_2.100 <- dat.kNN$tH2_VGrad_2.100
test_6$tH2_XGrad <- dat.kNN$tH2_XGrad
test_6$tH2_YGrad <- dat.kNN$tH2_YGrad
test_6$tpwHPA850 <- dat.kNN$tpwHPA850
test_6$ux1H10 <- dat.kNN$ux1H10
test_6$vapcSOL0 <- dat.kNN$vapcSOL0
test_6$vx1H10 <- dat.kNN$vx1H10
write.csv(test_6,paste0("R/NA/test/",files[6]),row.names = FALSE,fileEncoding = "utf-8")

new <- as.data.frame(test_7[,quanti[c(3:5,11:26)],with=FALSE])
dat.kNN=kNN(new, k=5, imp_var=FALSE)

test_7$ciwcH20 <- dat.kNN$ciwcH20
test_7$clwcH20 <- dat.kNN$clwcH20
test_7$ffH10 <- dat.kNN$ffH10
test_7$huH2 <- dat.kNN$huH2
test_7$iwcSOL0 <- dat.kNN$iwcSOL0
test_7$nbSOL0_HMoy <- dat.kNN$nbSOL0_HMoy
test_7$nH20 <- dat.kNN$nH20
test_7$ntSOL0_HMoy <- dat.kNN$ntSOL0_HMoy
test_7$pMER0 <- dat.kNN$pMER0
test_7$rr1SOL0 <- dat.kNN$rr1SOL0
test_7$rrH20 <- dat.kNN$rrH20
test_7$tH2 <- dat.kNN$tH2
test_7$tH2_VGrad_2.100 <- dat.kNN$tH2_VGrad_2.100
test_7$tH2_XGrad <- dat.kNN$tH2_XGrad
test_7$tH2_YGrad <- dat.kNN$tH2_YGrad
test_7$tpwHPA850 <- dat.kNN$tpwHPA850
test_7$ux1H10 <- dat.kNN$ux1H10
test_7$vapcSOL0 <- dat.kNN$vapcSOL0
test_7$vx1H10 <- dat.kNN$vx1H10
write.csv(test_7,paste0("R/NA/test/",files[7]),row.names = FALSE,fileEncoding = "utf-8")

files = list.files(path)

new <- as.data.frame(train_1[,quanti[c(1,3:5,11:26)],with=FALSE])
dat.kNN=kNN(new, k=5, imp_var=FALSE)
train_1$tH2_obs <- dat.kNN$tH2_obs
train_1$ciwcH20 <- dat.kNN$ciwcH20
train_1$clwcH20 <- dat.kNN$clwcH20
train_1$ffH10 <- dat.kNN$ffH10
train_1$huH2 <- dat.kNN$huH2
train_1$iwcSOL0 <- dat.kNN$iwcSOL0
train_1$nbSOL0_HMoy <- dat.kNN$nbSOL0_HMoy
train_1$nH20 <- dat.kNN$nH20
train_1$ntSOL0_HMoy <- dat.kNN$ntSOL0_HMoy
train_1$pMER0 <- dat.kNN$pMER0
train_1$rr1SOL0 <- dat.kNN$rr1SOL0
train_1$rrH20 <- dat.kNN$rrH20
train_1$tH2 <- dat.kNN$tH2
train_1$tH2_VGrad_2.100 <- dat.kNN$tH2_VGrad_2.100
train_1$tH2_XGrad <- dat.kNN$tH2_XGrad
train_1$tH2_YGrad <- dat.kNN$tH2_YGrad
train_1$tpwHPA850 <- new$tpwHPA850
train_1$ux1H10 <- dat.kNN$ux1H10
train_1$vapcSOL0 <- dat.kNN$vapcSOL0
train_1$vx1H10 <- dat.kNN$vx1H10
write.csv(train_1,paste0("R/NA/train/",files[1]),row.names = FALSE,fileEncoding = "utf-8")

new <- as.data.frame(train_2[,quanti[c(1,3:5,11:26)],with=FALSE])
dat.kNN=kNN(new, k=5, imp_var=FALSE)
train_2$tH2_obs <- dat.kNN$tH2_obs
train_2$ciwcH20 <- dat.kNN$ciwcH20
train_2$clwcH20 <- dat.kNN$clwcH20
train_2$ffH10 <- dat.kNN$ffH10
train_2$huH2 <- dat.kNN$huH2
train_2$iwcSOL0 <- dat.kNN$iwcSOL0
train_2$nbSOL0_HMoy <- dat.kNN$nbSOL0_HMoy
train_2$nH20 <- dat.kNN$nH20
train_2$ntSOL0_HMoy <- dat.kNN$ntSOL0_HMoy
train_2$pMER0 <- dat.kNN$pMER0
train_2$rr1SOL0 <- dat.kNN$rr1SOL0
train_2$rrH20 <- dat.kNN$rrH20
train_2$tH2 <- dat.kNN$tH2
train_2$tH2_VGrad_2.100 <- dat.kNN$tH2_VGrad_2.100
train_2$tH2_XGrad <- dat.kNN$tH2_XGrad
train_2$tH2_YGrad <- dat.kNN$tH2_YGrad
train_2$tpwHPA850 <- dat.kNN$tpwHPA850
train_2$ux1H10 <- dat.kNN$ux1H10
train_2$vapcSOL0 <- dat.kNN$vapcSOL0
train_2$vx1H10 <- dat.kNN$vx1H10
write.csv(train_2,paste0("R/NA/train/",files[2]),row.names = FALSE,fileEncoding = "utf-8")

new <- as.data.frame(train_3[,quanti[c(1,3:5,11:26)],with=FALSE])
dat.kNN=kNN(new, k=5, imp_var=FALSE)
train_3$tH2_obs <- dat.kNN$tH2_obs
train_3$ciwcH20 <- dat.kNN$ciwcH20
train_3$clwcH20 <- dat.kNN$clwcH20
train_3$ffH10 <- dat.kNN$ffH10
train_3$huH2 <- dat.kNN$huH2
train_3$iwcSOL0 <- dat.kNN$iwcSOL0
train_3$nbSOL0_HMoy <- dat.kNN$nbSOL0_HMoy
train_3$nH20 <- dat.kNN$nH20
train_3$ntSOL0_HMoy <- dat.kNN$ntSOL0_HMoy
train_3$pMER0 <- dat.kNN$pMER0
train_3$rr1SOL0 <- dat.kNN$rr1SOL0
train_3$rrH20 <- dat.kNN$rrH20
train_3$tH2 <- dat.kNN$tH2
train_3$tH2_VGrad_2.100 <- dat.kNN$tH2_VGrad_2.100
train_3$tH2_XGrad <- dat.kNN$tH2_XGrad
train_3$tH2_YGrad <- dat.kNN$tH2_YGrad
train_3$tpwHPA850 <- dat.kNN$tpwHPA850
train_3$ux1H10 <- dat.kNN$ux1H10
train_3$vapcSOL0 <- dat.kNN$vapcSOL0
train_3$vx1H10 <- dat.kNN$vx1H10
write.csv(train_3,paste0("R/NA/train/",files[3]),row.names = FALSE,fileEncoding = "utf-8")

new <- as.data.frame(train_4[,quanti[c(1,3:5,11:26)],with=FALSE])
dat.kNN=kNN(new, k=5, imp_var=FALSE)
train_4$tH2_obs <- dat.kNN$tH2_obs
train_4$ciwcH20 <- dat.kNN$ciwcH20
train_4$clwcH20 <- dat.kNN$clwcH20
train_4$ffH10 <- dat.kNN$ffH10
train_4$huH2 <- dat.kNN$huH2
train_4$iwcSOL0 <- dat.kNN$iwcSOL0
train_4$nbSOL0_HMoy <- dat.kNN$nbSOL0_HMoy
train_4$nH20 <- dat.kNN$nH20
train_4$ntSOL0_HMoy <- dat.kNN$ntSOL0_HMoy
train_4$pMER0 <- dat.kNN$pMER0
train_4$rr1SOL0 <- dat.kNN$rr1SOL0
train_4$rrH20 <- dat.kNN$rrH20
train_4$tH2 <- dat.kNN$tH2
train_4$tH2_VGrad_2.100 <- dat.kNN$tH2_VGrad_2.100
train_4$tH2_XGrad <- dat.kNN$tH2_XGrad
train_4$tH2_YGrad <- dat.kNN$tH2_YGrad
train_4$tpwHPA850 <- dat.kNN$tpwHPA850
train_4$ux1H10 <- dat.kNN$ux1H10
train_4$vapcSOL0 <- dat.kNN$vapcSOL0
train_4$vx1H10 <- dat.kNN$vx1H10
write.csv(train_4,paste0("R/NA/train/",files[4]),row.names = FALSE,fileEncoding = "utf-8")

new <- as.data.frame(train_5[,quanti[c(1,3:5,11:26)],with=FALSE])
dat.kNN=kNN(new, k=5, imp_var=FALSE)
train_5$tH2_obs <- dat.kNN$tH2_obs
train_5$ciwcH20 <- dat.kNN$ciwcH20
train_5$clwcH20 <- dat.kNN$clwcH20
train_5$ffH10 <- dat.kNN$ffH10
train_5$huH2 <- dat.kNN$huH2
train_5$iwcSOL0 <- dat.kNN$iwcSOL0
train_5$nbSOL0_HMoy <- dat.kNN$nbSOL0_HMoy
train_5$nH20 <- dat.kNN$nH20
train_5$ntSOL0_HMoy <- dat.kNN$ntSOL0_HMoy
train_5$pMER0 <- dat.kNN$pMER0
train_5$rr1SOL0 <- dat.kNN$rr1SOL0
train_5$rrH20 <- dat.kNN$rrH20
train_5$tH2 <- dat.kNN$tH2
train_5$tH2_VGrad_2.100 <- dat.kNN$tH2_VGrad_2.100
train_5$tH2_XGrad <- dat.kNN$tH2_XGrad
train_5$tH2_YGrad <- dat.kNN$tH2_YGrad
train_5$tpwHPA850 <- dat.kNN$tpwHPA850
train_5$ux1H10 <- dat.kNN$ux1H10
train_5$vapcSOL0 <- dat.kNN$vapcSOL0
train_5$vx1H10 <- dat.kNN$vx1H10
write.csv(train_5,paste0("R/NA/train/",files[5]),row.names = FALSE,fileEncoding = "utf-8")

new <- as.data.frame(train_6[,quanti[c(1,3:5,11:26)],with=FALSE])
dat.kNN=kNN(new, k=5, imp_var=FALSE)
train_6$tH2_obs <- dat.kNN$tH2_obs
train_6$ciwcH20 <- dat.kNN$ciwcH20
train_6$clwcH20 <- dat.kNN$clwcH20
train_6$ffH10 <- dat.kNN$ffH10
train_6$huH2 <- dat.kNN$huH2
train_6$iwcSOL0 <- dat.kNN$iwcSOL0
train_6$nbSOL0_HMoy <- dat.kNN$nbSOL0_HMoy
train_6$nH20 <- dat.kNN$nH20
train_6$ntSOL0_HMoy <- dat.kNN$ntSOL0_HMoy
train_6$pMER0 <- dat.kNN$pMER0
train_6$rr1SOL0 <- dat.kNN$rr1SOL0
train_6$rrH20 <- dat.kNN$rrH20
train_6$tH2 <- dat.kNN$tH2
train_6$tH2_VGrad_2.100 <- dat.kNN$tH2_VGrad_2.100
train_6$tH2_XGrad <- dat.kNN$tH2_XGrad
train_6$tH2_YGrad <- dat.kNN$tH2_YGrad
train_6$tpwHPA850 <- dat.kNN$tpwHPA850
train_6$ux1H10 <- dat.kNN$ux1H10
train_6$vapcSOL0 <- dat.kNN$vapcSOL0
train_6$vx1H10 <- dat.kNN$vx1H10
write.csv(train_6,paste0("R/NA/train/",files[6]),row.names = FALSE,fileEncoding = "utf-8")

new <- as.data.frame(train_7[,quanti[c(1,3:5,11:26)],with=FALSE])
dat.kNN=kNN(new, k=5, imp_var=FALSE)
train_7$tH2_obs <- dat.kNN$tH2_obs
train_7$ciwcH20 <- dat.kNN$ciwcH20
train_7$clwcH20 <- dat.kNN$clwcH20
train_7$ffH10 <- dat.kNN$ffH10
train_7$huH2 <- dat.kNN$huH2
train_7$iwcSOL0 <- dat.kNN$iwcSOL0
train_7$nbSOL0_HMoy <- dat.kNN$nbSOL0_HMoy
train_7$nH20 <- dat.kNN$nH20
train_7$ntSOL0_HMoy <- dat.kNN$ntSOL0_HMoy
train_7$pMER0 <- dat.kNN$pMER0
train_7$rr1SOL0 <- dat.kNN$rr1SOL0
train_7$rrH20 <- dat.kNN$rrH20
train_7$tH2 <- dat.kNN$tH2
train_7$tH2_VGrad_2.100 <- dat.kNN$tH2_VGrad_2.100
train_7$tH2_XGrad <- dat.kNN$tH2_XGrad
train_7$tH2_YGrad <- dat.kNN$tH2_YGrad
train_7$tpwHPA850 <- dat.kNN$tpwHPA850
train_7$ux1H10 <- dat.kNN$ux1H10
train_7$vapcSOL0 <- dat.kNN$vapcSOL0
train_7$vx1H10 <- dat.kNN$vx1H10
write.csv(train_7,paste0("R/NA/train/",files[7]),row.names = FALSE,fileEncoding = "utf-8")
