#####################
#### PACKAGE ########
#####################

library(data.table)
library(FactoMineR)
library("factoextra")
library(explor)
library(dplyr)

############################################################################
## OBJECTIF : creation de data.frame enrichie des coord des axes de l'ACP ##


## DEMARCHE ##

# 1 . chargment train et test

# 2 . concatenation data -> data_conc

# 3 . realisation de l'acp sur data_conc_num

## 3.1 garder axes representant 80% de l'inertie (au dela on considére que c'est du bruit)

## 3.2 rajouter les coord des axes aux data_conc

# 4 . separer le data_conc -> train_acp + test_acp


###########################################################################

# 1 .

data_agg=read.csv('Python/Pre-processing/data_meteo/data_agregated.csv',sep=';',dec='.',header=T,stringsAsFactors = FALSE,encoding = "UTF-8")
data_agg=data.table(data_agg)

test_agg=read.csv('Python/Pre-processing/data_meteo/test_agregated.csv',sep=';',dec='.',header=T,stringsAsFactors = FALSE,encoding = "UTF-8")
test_agg=data.table(test_agg)


# 2 .

data_conc=rbind(data_agg%>%select(-tH2_obs),test_agg)
data_conc=data.table(data_conc)

# 3 . realisation de l'acp sur data_conc_num


quanti <- names(data_conc)[sapply(data_conc,class)=="numeric"]
data_conc_num=data_conc[,quanti,with=FALSE]
data_conc_num=data_conc_num%>%select(-c(capeinsSOL0,rr1SOL0))
res_pca=PCA(data_conc_num,scale.unit = TRUE,ncp = 11)

## 3.1 garder axes representant 80% de l'inertie (au dela on considére que c'est du bruit)
eig.val <- get_eigenvalue(res_pca)

v=as.data.frame(res_pca$ind)[,1:11]


## 3.2 rajouter les coord des axes aux data_conc

data_conc_acp=cbind(data_conc,v)


# 4 . separer le data_conc -> train_acp + test_acp



train_acp=cbind(data_conc_acp[1:189280,],data_agg%>%select(tH2_obs))
test_acp=data_conc_acp[189281:210448,]

dim(train_acp)
dim(test_acp)
#### conclusion ecriture fichier CSV

write.csv(train_acp,"R/modif/data_acp.csv",row.names = FALSE,dec=".",sep=";",fileEncoding = "iso-8859-1")

write.csv(test_acp,"R/modif/test_acp.csv",row.names = FALSE,dec=".",sep=";",fileEncoding = "iso-8859-1")












