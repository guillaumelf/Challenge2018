library(corrplot)
library(ggplot2)
library(hydroGOF)
library(bestglm)
library(data.table)
library(dplyr)
library(leaps)
library(kernlab)

databig <- read.csv("R/data_meteo/data_agregated.csv",
                    header = TRUE,
                    sep = ";",
                    dec = ".",
                    stringsAsFactors = FALSE,
                    encoding = "UTF-8")
databig <- databig[,-1]


#Température à 2 mètres du modèle AROME

#Correlation totale
th2 <- databig$tH2
thobs <- databig$tH2_obs
thgrad <- databig$tH2_YGrad

cor.test(th2, thobs)
cor.test(th2, thgrad)
cor(th2, thobs, use = "complete.obs")
cor(th2, thgrad, use = "complete.obs")

#Correlation par échéance

coeff_vector <- rep(0, 36)

for (i in 1:36){
  th2 = databig[databig$ech == i,]$tH2
  thobs = databig[databig$ech == i,]$tH2_obs
  coeff_vector[i] = cor(th2, thobs, use = "complete.obs")
  
}
coeffs <- data.frame(ech = c(1:36), coeff = coeff_vector)
ggplot(coeffs) + geom_line(aes(x= ech, y=coeff), color = "red", lwd = 1.5) + theme_minimal() +
  geom_point(aes(x= ech, y=coeff), lwd = 3, color = "blue")


#Modèle linéaire basique (zéroooo)

#Test
obs <- 1:3
sim <- 3:5
rmse(obs, sim) #rmse=2

databig$ech <- as.factor(databig$ech)
databig$insee <- as.factor(databig$insee)
databig$date <- as.factor(databig$date)
databig$mois <- as.factor(databig$mois)
databig$ddH10_rose4 <- as.factor(databig$ddH10_rose4)

set.seed(123456)
n <- nrow(databig)
#ind.app <- sample(n, n*(1-nrow(test)/2/n))
ind.app <- sample(n, n*0.9)
dapp <- databig[ind.app, ]
dtest <- databig[-ind.app, ]


# dapps <- databig %>%
#   group_by(ech) %>%
#   do(sample_n(., size = 400))
# table(dapps$ech)

# dtest <- data.frame()
# n <- nrow(databig)
# for (i in 1:n){
#   if (dapps$date[i] %in% databig$date){
#     dtests = rbind(dtests, databig[i,])
#   }
# }
# dim(dapps)
# 14400/n
# 400*36
# table(databig$ech)
# table(dapp$ech)


modcomp <- lm(tH2_obs~., data = dapp[,-1])
modsvm <- ksvm(tH2_obs~tH2, data=dapp[,-1], C=1, scaled = F, type = "eps-bsvr")

prev <- predict(modsvm, newdata = dtest[,-1], type = "response")
prev=as.numeric(prev)
rmse(prev, dtest$tH2_obs)

prev2 <- predict(modcomp, newdata = dtest[,-1], type = "response")
rmse(prev, dtest$tH2_obs)

mod2 <- lm(tH2_obs~., data = dapp[,-c(1,9:12,20)])
prev2 <- predict(mod2, newdata = dtest[,-c(1,9:12,20)], type = "response")
rmse(prev2, dtest$tH2_obs)

test <- read.table("C:/Users/abdes/Desktop/Challenge2018/Challenge2018/R/data_meteo/test.csv",
                   sep = ";", header = TRUE, dec = ",")

test$ech <- as.factor(test$ech)
test$insee <- as.factor(test$insee)
test$date <- as.factor(test$date)
test$mois <- as.factor(test$mois)
test$flvis1SOL0 <- sub(",",".",test$flvis1SOL0)
test$flvis1SOL0 <- as.numeric(test$flvis1SOL0)
test$tH2_obs <- 0
class(test$tH2_obs)
test$ddH10_rose4 <- sub(".0","",test$ddH10_rose4)
table(test$ddH10_rose4)
test$ddH10_rose4 <- as.factor(test$ddH10_rose4)
class(test$ddH10_rose4)
test$mois <- as.factor(test$mois)
test$mois <- sub(levels(test$mois)[1], "août", test$mois)
test$mois <- as.factor(test$mois)
test$mois <- sub(levels(test$mois)[2], "décembre", test$mois)
test$mois <- as.factor(test$mois)
class(test$mois)
levels(test$mois)
table(test$mois)


prev_submit <- predict(modcomp, newdata = test[,-c(1,20)], type = "response")
prev_submit
prev_submit2 <- predict(mod2, newdata = test[,-c(1,20)], type = "response")
test$tH2_obs <- prev_submit
class(test$tH2_obs)
write.csv(prev_submit2, "complement.csv")

sum(is.na(prev))


mod2 <- lm(tH2_obs~ tH2 + tH2_YGrad, data = dapp[,-c(1,2)])

prev <- predict(mod2, newdata = dtest[,-c(1,2)], type = "response")
rmse(prev, dtest$tH2_obs)



modth2 <- lm(tH2_obs ~ tH2, data = dapp[,-c(1,2)])
table(dapp$ech)

prev <- predict(modth2, newdata = dtest, type = "response")
rmse(prev, dtest$tH2_obs)

mod_step <- step(modcomp, direction = "both", k = log(nrow(dapp)))
mod_step

prev <- predict(mod_step, newdata = dtest, type = "response")
rmse(prev, dtest$tH2_obs)

library(leaps)
a <- regsubsets(tH2_obs~., data = dapp[,-c(1,2)], nbest=1, method = "backward")
summary(a)
?regsubsets

plot(a)

#prev_submit <- predict(modzero, newdata = test, type = "response")
#prev_submit
#rmse(prev, dtest$tH2_obs)

#Bestglm
names(databig)
dataglm <- data.frame(databig[,-2], tH2_obs = databig$tH2_obs)

set.seed(123456789)
n <- nrow(dataglm)
#ind.app <- sample(n, n*(1-nrow(test)/2/n))
ind.app <- sample(n, n*0.9)
dappglm <- dataglm[ind.app, ]
dtestglm <- dataglm[-ind.app, ]

dappglm <- dappglm[complete.cases(dappglm), ]
#mod2 <- bestglm(dappglm, IC = "BIC")
#mod2$BestModel

#Stepwise
mod_step <- step(modzero, direction = "backward", k = log(nrow(dapp)))
mod_step

prev <- predict(mod_step, newdata = dtest, type = "response")
rmse(prev, dtest$tH2_obs)

prev_submit <- predict(modzero, newdata = test, type = "response")
prev_submit
rmse(prev, dtest$tH2_obs)



#Température potentielle au niveau 850 hPa

#Correlation totale
tpw <- databig$tpwHPA850
thobs <- databig$tH2_obs

cor.test(tpw, thobs)
cor(tpw, thobs, use = "complete.obs")

#Correlation par échéance

coeff_vector <- rep(0, 36)

for (i in 1:36){
  tpw = databig[databig$ech == i,]$tpwHPA850
  thobs = databig[databig$ech == i,]$tH2_obs
  coeff_vector[i] = cor(tpw, thobs, use = "complete.obs")
  
}
coeffs <- data.frame(ech = c(1:36), coeff = coeff_vector)
ggplot(coeffs) + geom_line(aes(x= ech, y=coeff), color = "red", lwd = 1.5) + theme_minimal() +
  geom_point(aes(x= ech, y=coeff), lwd = 3, color = "blue")


#train 1

train_1 <- read_delim("C:/Users/abdes/Desktop/Challenge2018/Challenge2018/R/data_meteo/train_1.csv", 
                      ";", escape_double = FALSE, trim_ws = TRUE)

set.seed(123456)
n <- nrow(train_1)
#ind.app <- sample(n, n*(1-nrow(test)/2/n))
ind.app <- sample(n, n*0.9)
dapp <- train_1[ind.app, ]
dtest <- train_1[-ind.app, ]
dapp <- na.omit(dapp)

modzero <- lm(tH2_obs ~ tH2, data = dapp)
?lm
prev <- predict(modzero, newdata = dtest, type = "response")
rmse(prev, dtest$tH2_obs)