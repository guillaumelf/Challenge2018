#######################################################
#### Modélisation des variables, serie temporelle  ####
#######################################################

# Exemple d'utilisation des séries temporelles pour faire de la prédiction

library(tseries)

data(AirPassengers)
AirPassengers
adf.test(diff(log(AirPassengers)), alternative="stationary", k=0)
acf(diff(log(AirPassengers)))
pacf(diff(log(AirPassengers)))
fit <- arima(log(AirPassengers), c(0, 1, 1),seasonal = list(order = c(0, 1, 1), period = 12))
pred <- predict(fit, n.ahead = 10*12)
ts.plot(AirPassengers,2.718^pred$pred, log = "y", lty = c(1,3))

# Essayons de refaire le même type de manipulation avec nos données

library(data.table)
library(ggplot2)

sum_na <- function(x){
  return(sum(is.na(x)))
}

# On importe les données de la station de Toulouse

chemin <- "Python/Pre-processing/data_agg_sep/31069001.csv"
Toulouse <- data.table(read.csv(chemin,
                            header = TRUE,
                            sep = ";",
                            dec = ".",
                            stringsAsFactors = TRUE,
                            encoding = "UTF-8"))[,-c(1,2)]

Toulouse[, c("date","ech") := .(as.IDate(date),as.factor(ech))]

# On représente la variable capeinsSOL0 pour toutes les échéances

ggplot(Toulouse)+aes(x=date,y=capeinsSOL0)+geom_line()+
  theme(plot.title = element_text(hjust = 0.5))+facet_wrap(~ech)

# Puis on regarde son lien avec la température

ggplot(Toulouse)+aes(x=capeinsSOL0,y=tH2_obs)+geom_point()+
  geom_smooth(method = lm,size=1.5)+labs(title = "tH2_obs en fonction de capeinsSOL0")+
  theme(plot.title = element_text(hjust = 0.5))

# Il va falloir y aller au cas par cas
# Focus sur l'échance 1

ech_1 <- Toulouse[ech == 1, .(date,capeinsSOL0)]
rownames(ech_1) <- ech_1$date
ech_1[, date := NULL]
sapply(ech_1,sum_na)

test <- ts(ech_1[1:40])
complet <- ts(ech_1[1:77])
plot.ts(test)


adf.test(test, alternative="stationary", k=0)
acf(test) # => p = 0
pacf(test) 
fit <- arima(test, c(0, 1, 1),seasonal = list(order = c(0, 1, 1), period = 2))
pred <- predict(fit, n.ahead = 37)
par(mfrow = c(2,1))
ts.plot(test,pred$pred, lty = c(1,3), col = c(1,3))
plot.ts(complet)
