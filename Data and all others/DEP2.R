library(tidyverse)
library(dplyr)

data <- read_csv("Unemplyment_data2.csv")

View(data)

datanew <- data %>% gather(key = Year , value = Unemployment_percentage , -`Country Code`, -`Indicator Name`, -`Indicator Code`, -`Country Name`)%>%
  select(`Country Name`, Year , Unemployment_percentage)%>% 
  filter(!is.na(Unemployment_percentage))


write_csv(x = datanew, file = "Unemployment_cleaned.csv")


