library(dplyr)
library(tidyr)
library(lubridate)

# install.packages(c("sf", "tmap", "rnaturalearth", "rnaturalearthdata"))
library(sf)
library(tmap)
library(rnaturalearth)
tmap_options(check.and.fix = TRUE)


popup_df <- read_csv("PopupDB_FromTableau2.csv")
unemployment_df <- read_csv("Unemployment_cleaned.csv")


merged_df <- merge(popup_df, unemployment_df, by.x="Website_country", by.y="Country Name", all.x=FALSE, all.y=FALSE)

# for the graph of the choropleth map 

merged_df$Date <- year(dmy_hms(merged_df$Date))

count_df <- merged_df %>%
  group_by(Website_country, Year, Unemployment_percentage) %>%
  summarise(Count = n(), )

pivot_count_df <- count_df %>%
  spread(key = Year, value = Unemployment_percentage) %>%
  group_by(Website_country, Count) %>%
  summarise(Difference = `2020` - `2021`)

pivot_count_df <- unique(pivot_count_df)



world <- ne_countries(scale = "medium", returnclass = "sf")

merged_map_data <- merge(world, pivot_count_df, by.x="name", by.y="Website_country")

gradient_palette <- colorRampPalette(c("green", "red"))

tm_shape(merged_map_data) + 
  tm_polygons("Difference", title="Unemployment change from 2020 to 2021 %",
              palette = gradient_palette(100),  # Here 100 represents the number of colors in the gradient
              midpoint = 0,  
              style = "cont" ) + 
  tm_layout(title="Year-over-Year Unemployment Percentage by Country")
