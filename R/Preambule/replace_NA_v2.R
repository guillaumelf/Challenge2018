##################################################
#### Remplacement des NA dans le fichier test ####
##################################################

library(data.table)
library(ggplot2)

test <- data.table(read.csv("Python/Pre-processing/test_sep/31069001.csv",
                            header = TRUE,
                            sep = ";",
                            dec = ".",
                            stringsAsFactors = TRUE,
                            encoding = "UTF-8"))[,-1]

dec <- test[date == "2016-12-06"]

ggplot(dec)+aes(x=ech,y=flir1SOL0)+geom_line(col="blue")+
  labs(title = "")+
  theme(plot.title = element_text(hjust = 0.5))

ggplot(dec)+aes(x=ech,y=fllat1SOL0)+geom_line(col="blue")+
  labs(title = "")+
  theme(plot.title = element_text(hjust = 0.5))

ggplot(dec)+aes(x=ech,y=flsen1SOL0)+geom_line(col="blue")+
  labs(title = "")+
  theme(plot.title = element_text(hjust = 0.5))

ggplot(dec)+aes(x=ech,y=flvis1SOL0)+geom_line(col="blue")+
  labs(title = "")+
  theme(plot.title = element_text(hjust = 0.5))

# On va remplacer pour chaque fichier les NA du mois de decembre échéance 1 par les valeurs de l'echeance 2 du meme mois

path <- "Python/Pre-processing/test_sep"
for (file in list.files(path)){
  chemin <- paste0("Python/Pre-processing/test_sep/",file)
  test <- data.table(read.csv(chemin,
                              header = TRUE,
                              sep = ";",
                              dec = ".",
                              stringsAsFactors = TRUE,
                              encoding = "UTF-8"))[,-1]
  test[57:70,]$flir1SOL0 <- test[141:154,]$flir1SOL0
  test[57:70,]$fllat1SOL0 <- test[141:154,]$fllat1SOL0
  test[57:70,]$flsen1SOL0 <- test[141:154,]$flsen1SOL0
  test[57:70,]$flvis1SOL0 <- test[141:154,]$flvis1SOL0
  destination <- paste0("Python/Pre-processing/test_sep_NAfilled/",file)
  write.csv2(test,destination, sep = ";")
}
