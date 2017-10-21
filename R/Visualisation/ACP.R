#####################
#### PACKAGE ########
#####################

library(data.table)
library(FactoMineR)
library("factoextra")

######################
#### IMPORTATION #####
######################

data_agg=read.csv('data_meteo/data_agregated.csv',sep=';',dec='.',header=T,stringsAsFactors = FALSE,encoding = "UTF-8")
data_agg=data.table(data_agg)

################################
#### MISE EN FORME DU DATA #####
################################

type <- data.frame(type = sapply(data_agg,class))
type

# enlevement des NA
data_na=na.omit(data_agg)

# enlever X, ech
data=data_na[,c(-1,-31)]
# mise en facteur des var concernees
data$ddH10_rose4=as.factor(data$ddH10_rose4)
data$insee=as.character(data$insee)
data$mois=as.factor(data$mois)
data$date=as.factor(data$date)

transfo <- c("6088001" = "Nice",
             "31069001" = "Toulouse_Blagnac",
             "33281001" = "Bordeaux_Mérignac",
             "35281001" = "Rennes",
             "59343001" = "Lille_Lesquin",
             "67124001" = "Strasbourg_Entzheim",
             "75114001" = "Paris_Montsouris")
data$insee <- transfo[data$insee]
data$insee <- as.factor(data$insee)



################################
######      ACP       ##########
################################


################################
### ACP avec la variable cible

quanti <- names(data)[sapply(data,class)=="numeric"]

d_acp=data[,quanti,with=FALSE]

res_pca=PCA(d_acp,scale.unit = TRUE,ncp = 11)

eig.val <- get_eigenvalue(res_pca) # 80% de l'inertie à partir de dim11 -> ncp=11

# visu
# cos 2
fviz_pca_var(res_pca, col.var = "cos2",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE)
# contribution
fviz_pca_var(res_pca, col.var = "contrib",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07")
)


# Representation des individus

fviz_pca_ind(res_pca,
             geom.ind = "point", # Montre les points seulement (mais pas le "text")
             col.ind = data$insee, # colorer by groups
             palette = c("#00AFBB", "#E7B800", "#FC4E07",6,7,8,9),
             addEllipses = TRUE, # Ellipses de concentration
             legend.title = "Groups"
)


################################
### ACP SANS la variable cible

d_acp2=d_acp
d_acp2[,"tH2_obs" := NULL]

res2_pca=PCA(d_acp2,scale.unit = TRUE,ncp = 11)

eig.val <- get_eigenvalue(res2_pca) # 80% de l'inertie à partir de dim11 -> ncp=11

# visu
# cos 2
fviz_pca_var(res2_pca, col.var = "cos2",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE)
# contribution
fviz_pca_var(res2_pca, col.var = "contrib",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07")
)


# Representation des individus

fviz_pca_ind(res2_pca,
             geom.ind = "point", # Montre les points seulement (mais pas le "text")
             col.ind = data$insee, # colorer by groups
             palette = c("#00AFBB", "#E7B800", "#FC4E07",6,7,8,9),
             addEllipses = TRUE, # Ellipses de concentration
             legend.title = "Groups"
)



#####################################
### ACP pour le jeu de données test

# Nettoyage data test

test=read.csv('data_meteo/test.csv',sep=';',dec=',',header=T,stringsAsFactors = FALSE,encoding = "UTF-8")
test=data.table(test)
test=na.omit(test)
test[, "date" := NULL]
test[, c("insee",
          "ddH10_rose4",
          "ech",
          "mois") := list(factor(insee),
                          factor(ddH10_rose4),
                          factor(ech),
                          factor(mois))]

transfo <- c("6088001" = "Nice",
             "31069001" = "Toulouse_Blagnac",
             "33281001" = "Bordeaux_Mérignac",
             "35281001" = "Rennes",
             "59343001" = "Lille_Lesquin",
             "67124001" = "Strasbourg_Entzheim",
             "75114001" = "Paris_Montsouris")
test$insee <- transfo[test$insee]
test$insee <- as.factor(test$insee)

# go
q_test <- names(test)[sapply(test,class)=="numeric"]

acp_test=test[,q_test,with=FALSE]

res_test=PCA(acp_test,scale.unit = TRUE,ncp = 11)

eig.val <- get_eigenvalue(res_test) # 80% de l'inertie à partir de dim11 -> ncp=11

# visu
# cos 2
fviz_pca_var(res_test, col.var = "cos2",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE)
# contribution
fviz_pca_var(res_test, col.var = "contrib",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07")
)


# Representation des individus

fviz_pca_ind(res_test,
             geom.ind = "point", # Montre les points seulement (mais pas le "text")
             col.ind = test$insee, # colorer by groups
             palette = c("#00AFBB", "#E7B800", "#FC4E07",6,7,8,9),
             addEllipses = TRUE, # Ellipses de concentration
             legend.title = "Groups"
)


# Nous pouvons voir qu'il y a des outliers dans le fichier test aussi -> ne pas les enlever des fichiers train






