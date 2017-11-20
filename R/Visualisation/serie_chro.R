#######################################################
#### Modélisation des variables, serie temporelle  ####
#######################################################

library(data.table)
library(ggplot2)

sum_na <- function(x){
  return(sum(is.na(x)))
}

chemin <- "Python/Pre-processing/data_agg_sep/31069001.csv"
Toulouse <- data.table(read.csv(chemin,
                            header = TRUE,
                            sep = ";",
                            dec = ".",
                            stringsAsFactors = TRUE,
                            encoding = "UTF-8"))[,-c(1,2)]

Toulouse[, c("date","ech") := .(as.IDate(date),as.factor(ech))]

# Variable capeinsSOL0

ech_1 <- Toulouse[ech == 1, .(date,capeinsSOL0)]
sapply(ech_1,sum_na)
ech_1[is.na(capeinsSOL0)]

ggplot(ech_1)+aes(x=date,y=capeinsSOL0)+geom_line()+
  labs(title = "")+
  theme(plot.title = element_text(hjust = 0.5))

# Pour toutes les échéances

ggplot(Toulouse)+aes(x=date,y=capeinsSOL0)+geom_line()+
  theme(plot.title = element_text(hjust = 0.5))+facet_wrap(~ech)

# Focus sur l'échance 1

