library(dplyr)
library(tidyr)


popup_df <- read_csv("PopupDB_FromTableau2.csv")
unemployment_df <- read_csv("Unemployment_cleaned.csv")

colnames(unemployment_df)
colnames(popup_df)

merged_df <- merge(popup_df, unemployment_df, by.x="Website_country", by.y="Country Name", all.x=FALSE, all.y=FALSE)


# merged_df$Date <- as.Date(merged_df$Date) 
merged_df$Date <- year(dmy_hms(merged_df$Date))


# Group by Website_country and Year, then count rows
count_df <- merged_df %>%
  group_by(Website_country, year(Date)) %>%
  summarise(Count = n())

# Pivot the data to get counts for the two years in separate columns
pivot_count_df <- count_df %>%
  spread(key = Year, value = Count) %>%
  group_by(Website_country) %>%
  summarise(Difference = `2020` - `2021`)

# Remove any duplicate rows
pivot_count_df <- unique(pivot_count_df)




library(tidyr)

pivot_df <- merged_df %>%
  spread(key = Year, value = Unemployment_percentage) %>%
  group_by(Website_country) %>%
  summarise(Difference = (`2020` - `2021`)/`2020` )

pivot_df <- unique(pivot_df)



install.packages(c("sf", "tmap", "rnaturalearth", "rnaturalearthdata"))
library(sf)
library(tmap)
library(rnaturalearth)

world <- ne_countries(scale = "medium", returnclass = "sf")

merged_map_data <- merge(world, merged_df, by.x="name", by.y="Website_country")

tm_shape(merged_map_data) + 
  tm_polygons("Unemployment_percentage", title="Unemployment %") + 
  tm_facets(by="Year", ncol=2) +
  tm_layout(title="Year-over-Year Unemployment Percentage by Country")
