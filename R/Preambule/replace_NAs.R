################################################
### Remplacement des NA dans le fichier test ###
################################################

### Import de librairies
########################

library(data.table)

### Exemple introductif
#######################

df <- data.table("id1" = c(1,2,1,2,1,2,1,2), "id2" = c(1,1,2,2,1,1,2,2), "V1" = c(18,36.5,78,44,NA,89,NA,13),
                             "V2" = c(NA,53,89,NA,19,NA,23,56),"ligne" = c(1,2,3,4,5,6,7,8))
impute.mean <- function(x) replace(x, is.na(x), mean(x, na.rm = TRUE))
df <- df[, lapply(.SD, impute.mean), by = .(id1,id2)][order(ligne)]

### Application sur le fichier test
###################################

# Importation

test <- data.table(read.csv("R/data_meteo/test.csv",
                             header = TRUE,
                             sep = ";",
                             dec = ",",
                             stringsAsFactors = TRUE,
                             encoding = "UTF-8"))

# Transformation des donnees pour les exploiter

date <- test$date
test[, date := NULL]
test[, c("insee",
          "ddH10_rose4",
          "ech",
          "mois",
         "flvis1SOL0") := list(factor(insee),
                          factor(ddH10_rose4),
                          factor(ech),
                          factor(mois),
                          as.numeric(gsub(",",".",flvis1SOL0)))]

# Rajout d'une variable fictive : le numero de ligne pour conserver le meme ordre que dans le fichier initial

test$ligne <- 1:nrow(test)

# Recapitulatif

sum_na <- function(x){
  return(sum(is.na(x)))
}

sapply(test,class)
sapply(test,sum_na)

### Remplacement des NA par moyennes groupées (par station, mois et echeance)
#############################################################################

new_test <- test[, lapply(.SD, impute.mean), by = .(insee,mois,ech)][order(ligne)]
sapply(new_test,sum_na)

# Probleme non resolu par cette methode
