########################
### Regression LASSO ###
########################

### Import de librairies
########################

library(data.table)
library(glmnet)
library(doParallel)
library(parallel)

### Importation des donnees
###########################

test <- data.table(read.csv("R/data_meteo/test.csv",
                            header = TRUE,
                            sep = ";",
                            dec = ",",
                            stringsAsFactors = TRUE,
                            encoding = "UTF-8"))

sum_na <- function(x){
  return(sum(is.na(x)))
}
sapply(test,sum_na)

# Les variables à retirer : flir1SOL0, fllat1SOL0, flsen1SOL0, rr1SOL0

test[, c("insee",
          "ddH10_rose4",
          "ech",
          "mois",
          "flvis1SOL0") := list(factor(insee),
                                factor(ddH10_rose4),
                                factor(ech),
                                factor(mois),
                                as.numeric(gsub(",",".",flvis1SOL0)))]
test[, c("date","flir1SOL0", "fllat1SOL0", "flsen1SOL0", "rr1SOL0") := NULL]

train <- data.table(read.csv("R/data_meteo/data_agregated.csv",
                            header = TRUE,
                            sep = ";",
                            dec = ".",
                            stringsAsFactors = TRUE,
                            encoding = "UTF-8"))

# Transformation des donnees pour les exploiter

train[, c("date","X","flir1SOL0", "fllat1SOL0", "flsen1SOL0", "rr1SOL0") := NULL]
train[, c("insee",
         "ddH10_rose4",
         "ech",
         "mois") := list(factor(insee),
                               factor(ddH10_rose4),
                               factor(ech),
                               factor(mois))]
sapply(train,class)

train <- na.omit(train)

### Modelisation avec la regression Lasso
#########################################

X <- sparse.model.matrix(tH2_obs~., data = train)
y <- train$tH2_obs


cl <- makeCluster(4)
registerDoParallel(cl)
reg.lasso <- cv.glmnet(X,y, lambda = seq(0,2,by = 0.1), type.measure = "mse", nfolds = 10, parallel = TRUE)
stopCluster(cl)

plot(reg.lasso)
sqrt(reg.lasso$cvm)
reg.lasso$lambda.min

reg.lasso <- glmnet(X,y,family = "gaussian", alpha = 1)
predict(reg.lasso,newx = )