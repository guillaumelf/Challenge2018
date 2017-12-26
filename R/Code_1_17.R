#AZNAGUE Abdessamad
#24 Décembre 2017

data <- read.csv("C:/Users/abdes/Desktop/Challenge2018/DL_ben.csv", sep = ";")

data$ech <- as.factor(data$ech)
data$insee <- as.factor(data$insee)
data$date <- as.Date(data$date, format = "%Y-%m-%d")
data$pred <- data$tH2_obs
data$newpred <- data$tH2_obs
sapply(data, function(x) class(x))

insee <- levels(data$insee)
dates <- unique(data$date)

isEmpty <- function(x){
  return(length(x)==0)
}

for(d in 1:83){
  if(dates[d]+1 %in% dates){
    for(s in 1:7){
      for(i in 25:36){
        if(!isEmpty(data[data$date==dates[d] & data$insee==insee[s] & data$ech==i, ]$newpred) & 
           !isEmpty(data[data$date==dates[d]+1 & data$insee==insee[s] & data$ech==(i-24), ]$pred))
          data[data$date==dates[d] & data$insee==insee[s] & data$ech==i, ]$newpred <-
            data[data$date==dates[d]+1 & data$insee==insee[s] & data$ech==(i-24), ]$pred
      }
    }
  }
}

write.csv(data$newpred, "TESTULTIM_final.csv")

