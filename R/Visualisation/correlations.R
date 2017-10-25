#####################################################################
### Visualisation : analyse de la correlation entre les variables ###
### et de l'importance (biais) des differentes stations, mois,... ###
#####################################################################

# Installez les 3 premieres librairies avant d'executer

require(glasso)
require(qgraph)
require(fields)
require(data.table)
require(FactoMineR)
require(ggplot2)

# Importation des donnees

train <- data.table(read.csv("R/data_meteo/data_agregated.csv",
                             header = TRUE,
                             sep = ";",
                             dec = ".",
                             stringsAsFactors = FALSE,
                             encoding = "UTF-8"))

# Transformation des donnees pour regarder les correlations

train[, c("X","date") := NULL]
train[, c("insee",
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
train$insee <- transfo[train$insee]
train$insee <- as.factor(train$insee)

matrice <- data.frame(model.matrix(tH2_obs~insee+ddH10_rose4+ech+mois-1,data=train))

# Certaines lignes ont ete suprimees, on va donc fusionner pour faire correspondre les lignes restantes

matrice$n <- rownames(matrice)
new_train <- train[, -c("insee","ddH10_rose4","ech","mois")]
new_train$n <- rownames(train)

matrice <- data.table(matrice)
setkey(matrice,n)
setkey(new_train,n)

matrice <- matrice[new_train,nomatch=0]
matrice[, n := NULL]

# Matrice des correlations entre nos variables

matrice[, c("tpwHPA850","rr1SOL0","pMER0","nH20","flvis1SOL0",
            "flsen1SOL0","clwcH20","ciwcH20","capeinsSOL0","flir1SOL0","fllat1SOL0") := NULL]
mat_cor <- cor(matrice)

###############################
# Representations avec qgraph #
###############################

# Utilisation d'une penalite Lasso (parametre rho) pour regler le nombre de relations a afficher sur le graphe
# => plus la penalite sera forte (proche de 1) plus la contrainte sera elevee et le nombre de relations sera faible.

# On commence avec la penalite 0

a = glasso(mat_cor,rho = 0)
qgraph(a, layout="spring",
       labels=names(matrice), label.scale=FALSE,
       label.cex=1, node.width=1)

# On augmente a 0.25

a = glasso(mat_cor,rho = 0.25)
qgraph(a, layout="spring",
       labels=names(matrice), label.scale=FALSE,
       label.cex=1, node.width=1)

# On augmente a 0.5

a = glasso(mat_cor,rho = 0.5)
qgraph(a, layout="spring",
       labels=names(matrice), label.scale=FALSE,
       label.cex=1, node.width=1)

##########################
# Analyse complementaire #
##########################

quanti <- names(train)[sapply(train,class)=="numeric"]
quali <- names(train)[sapply(train,class)!="numeric"]

pca_data <- train[, quanti,with=FALSE]
mca_data <- train[, quali,with=FALSE]

# ACP des variables quantitatives

res_pca <- PCA(X = pca_data)

# ACM des variables qualitatives

res_mca <- MCA(X = mca_data)

# Resultats interessants avec l'ACP, pas specialement avec l'ACM

ggplot(train)+aes(x=tH2,y=tH2_obs)+geom_point()+
  geom_smooth(method = lm,size=1.5)+labs(title = "tH2_obs en fonction de tH2")+
  theme(plot.title = element_text(hjust = 0.5))


ggplot(train)+aes(x=tH2_YGrad,y=tH2_obs)+geom_point()+
  labs(title = "tH2_obs en fonction de tH2_YGrad")+
  theme(plot.title = element_text(hjust = 0.5))

ggplot(train)+aes(x=hcoulimSOL0,y=tH2_obs)+geom_point()+
  labs(title = "tH2_obs en fonction de hcoulimSOL0")+
  theme(plot.title = element_text(hjust = 0.5))

ggplot(train)+aes(x=capeinsSOL0,y=tH2_obs)+geom_point()+
  labs(title = "tH2_obs en fonction de capeinsSOL0")+
  theme(plot.title = element_text(hjust = 0.5))

ggplot(train)+aes(x=mois,y=tH2_obs)+geom_boxplot(aes(fill=mois))+
  scale_x_discrete(limits=c("janvier","février","mars","avril","mai","juin","juillet","août","septembre","octobre",
                            "novembre","décembre"))

ggplot(na.omit(train))+aes(x=ddH10_rose4,y=tH2_obs)+geom_boxplot(aes(fill=ddH10_rose4))+facet_wrap(~insee, nrow=2)


ggplot(train)+aes(x=ech,y=tH2_obs)+geom_boxplot(aes(fill=ech))
