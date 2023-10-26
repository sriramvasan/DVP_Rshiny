library(shiny)
library(dplyr)
library(tidyr)
library(lubridate)
library(sf)
library(tmap)
library(rnaturalearth)
library(networkD3)
library(ggplot2)
library(lwgeom)
library(readr)
library(leaflet)
library(geosphere)

tmap_options(check.and.fix = TRUE)


popup_df <- read_csv("PopupDB_FromTableau2.csv")
unemployment_df <- read_csv("Unemployment_cleaned.csv")
merged_df <- merge(popup_df, unemployment_df, by.x="Website_country",
                   by.y="Country Name", all.x=FALSE, all.y=FALSE)

merged_df$Date <- year(dmy_hms(merged_df$Date))

# scams_count_df <- merged_df %>%
#   group_by(Website_country, Date, `Ip Orgs`) %>%
#   summarise(Count = n(), )

scams_difference_country <- unique(merged_df %>%
                            group_by(Website_country, Date) %>%
                            summarise(Count = n(), )%>%
                             spread(key = Date,  value = Count)%>% 
                             group_by(Website_country) %>%
                             reframe(scams_Difference = (`2021`-`2020`)/`2020`)%>%
                             drop_na(scams_Difference) )

scams_difference_orgs <- unique(scams_count_df %>%
                                  group_by(`Ip Orgs`, Date) %>%
                                  summarise(Count = n(), )%>%
                                   spread(key = Date,  value = Count)%>% 
                                   group_by(`Ip Orgs`) %>%
                                   reframe(scams_Difference = (`2021`-`2020`)/`2020`)%>%
                                  filter(scams_Difference != 0)%>% 
                                   drop_na(scams_Difference) )
              

unemp_difference_country <- unique(merged_df %>%
                            group_by(Website_country, Unemployment_percentage, Year) %>%
                            summarise(Count = n(), )%>%
                             spread(key = Year, value = Unemployment_percentage) %>%
                             group_by(Website_country) %>%
                             reframe(unemp_Difference = `2020` - `2021`))


ggplot(scams_difference_country, aes(x = reorder(Website_country, -scams_Difference), y = scams_Difference)) +
  geom_bar(stat="identity", fill = ifelse(scams_difference_country$scams_Difference > 0, "lightgreen", "coral")) + 
  coord_flip() +
  labs(title = "Year over Year Change in Scams by Country", y = "Difference", x = "") +
  theme_minimal()+ 
theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())




ggplot(scams_difference_orgs, aes(x = reorder(`Ip Orgs`, -scams_Difference ), y = scams_Difference)) +
  geom_bar(stat="identity", fill = ifelse(scams_difference_orgs$scams_Difference > 0, "lightgreen", "coral")) +
  coord_flip() +
  labs(title = "Year over Year Change in Scams by Orgs", y = "Difference", x = "") +
  theme_minimal()+ 
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

# changes from 

ggplot(unemp_difference_country, aes(x = reorder(Website_country, -unemp_Difference), y = unemp_Difference)) +
  geom_bar(stat="identity", fill = ifelse(unemp_difference_country$unemp_Difference > 0, "lightgreen", "coral")) +
  coord_flip() +
  labs(title = "Year over Year Change in Unemployment by Country", y = "Difference", x = "") +
  theme_minimal()+ 
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
