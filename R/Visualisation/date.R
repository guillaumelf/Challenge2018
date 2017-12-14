library(ggplot2)
data <- read.csv('transfo_dates.csv',sep=";")
data$date <- as.Date(data$date)
ggplot(data)+aes(x=date,y=coordonnees)+geom_line(color="red",size=1.5)+scale_x_date(date_breaks = "4 months")
