##################################
# Visualisation Serie temporelle #
##################################

library(data.table)

data_loc <- data.table(read.csv("R/data_meteo/localisation.csv",
                                header = TRUE,
                                sep = ",",
                                stringsAsFactors = FALSE,
                                encoding = "UTF-8"))
data_loc <- data_loc[, X := NULL]

train <- data.table(read.csv("R/data_meteo/data_agregated.csv",
                               header = TRUE,
                               sep = ";",
                               dec = ".",
                               stringsAsFactors = FALSE,
                               encoding = "UTF-8"))

train[, X := NULL]

train$insee <- as.factor(train$insee)
data_loc$code <- as.factor(data_loc$code)
setkey(train,insee)
setkey(data_loc,code)
data <- train[data_loc,nomatch=0]
data[, date := as.Date(date)]
data[, ech := as.factor(ech)]
collection <- unique(data$ville)
for (city in collection){
  assign(city,data[ville == city])
}

# Exemple de graph pour Nice

library(ggplot2)

ggplot(Nice)+aes(x=date, y = tH2_obs)+geom_line() + 
  scale_x_date(date_breaks = "1 month") + facet_wrap(~ech,nrow=2) + ylab("Temperature")

hist(Nice$tH2_obs)

# Manque d'inofs a partir de ech = 30











