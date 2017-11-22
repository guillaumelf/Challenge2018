####################
###### FONCTION ####

fac=function(test){
  test$ech <- as.factor(test$ech)
  test$insee <- as.factor(test$insee)
  test$date <- as.factor(test$date)
  test$mois <- as.factor(test$mois)
  test$ddH10_rose4 <- as.factor(test$ddH10_rose4)
  test
}

sum_na <- function(x){
  return(sum(is.na(x)))
}