library(shiny)
library(dplyr)
library(tidyr)
library(lubridate)
library(sf)
library(tmap)
library(rnaturalearth)
library(networkD3)
library(ggplot2)
library(rnaturalearth)

# install.packages("lwgeom")
library(lwgeom)


tmap_options(check.and.fix = TRUE)


popup_df <- read_csv("PopupDB_FromTableau2.csv")
unemployment_df <- read_csv("Unemployment_cleaned.csv")


merged_df <- merge(popup_df, unemployment_df, by.x="Website_country", by.y="Country Name", all.x=FALSE, all.y=FALSE)

country_counts <- merged_df %>%
  group_by(Website_country, Phone_country) %>%
  summarise(Count = n())

country_counts_diff <- country_counts %>% filter(Website_country != Phone_country)
# country_counts_diff <-  country_counts_diff %>% filter( Count > 10 )


# Prepare world data
world <- st_as_sf(maps::map('world', plot = FALSE, fill = TRUE))
world_valid <- st_make_valid(world)


# Calculate centroids
country_centroids <- st_centroid(world_valid)
country_centroids_df <- data.frame(st_coordinates(st_geometry(country_centroids)))
names(country_centroids_df) <- c("lon", "lat")
# country_centroids_df$country <- world$name_long
country_centroids_df <- cbind(country_centroids_df, country = world$ID)

# Join data with centroids
data <- country_counts %>%
  left_join(country_centroids_df, by = c("Website_country" = "country")) %>%
  rename(website_lon = lon, website_lat = lat) %>%
  left_join(country_centroids_df, by = c("Phone_country" = "country")) %>%
  rename(phone_lon = lon, phone_lat = lat)

# Plot
ggplot(data = world) + 
  geom_sf(fill = "white", color = "black") +
  geom_segment(data = data, 
               aes(x = website_lon, y = website_lat, xend = phone_lon, yend = phone_lat),
               arrow = arrow(length = unit(0.2, "inches")), 
               size = data$Count / max(data$Count) * 100, # adjust for desired line thickness
               color = "coral") + 
  coord_sf(crs = st_crs(world), datum = NA) +
  theme_minimal()


adjusted_data <- data %>%
  mutate(
    phone_lon = ifelse(website_lon == phone_lon & website_lat == phone_lat, phone_lon + 0.5, phone_lon),
    phone_lat = ifelse(website_lon == phone_lon & website_lat == phone_lat, phone_lat + 0.5, phone_lat)
  )



ggplot(data = world) + 
  geom_sf(fill = "white", color = "black") +
  geom_curve(data = adjusted_data, 
             aes(x = website_lon, y = website_lat, xend = phone_lon, yend = phone_lat),
             curvature = 0.1, # Control the curvature of the lines. Adjust as needed.
             arrow = arrow(length = unit(0.2, "inches")), 
             size = (data$Count / max(data$Count) ) * 50, 
             color = "red") + 
  coord_sf(crs = st_crs(world), datum = NA) +
  theme_minimal()

