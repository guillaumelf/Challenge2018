library(ggplot2)
data <- read.csv('transfo_dates.csv',sep=";")
data$date <- as.Date(data$date)
ggplot(data)+aes(x=date,y=coordonnees)+geom_line(color="red",size=1.5)+scale_x_date(date_breaks = "4 months")

library(rAmCharts)
res_forest <- data.frame(file=c("train","test","baseline"),score=c(1.05910,1.30753,1.30755),color=c("#10EA00","#F77C00","#F41000"))
amBarplot(x = "file", y = "score", data = res_forest, depth = 15, labelRotation = -45,show_values = TRUE,legend=TRUE,
          main = "Comparaison du score moyen sur les fichiers train avec la baseline et la réalité",export=TRUE,
          ylim = c(0,1.50))
