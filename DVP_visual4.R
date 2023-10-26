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

# UI definition
ui <- fluidPage(
  titlePanel("Mapped Website and Phone Countries"),
    column(12, align = "centre",
      tabsetPanel(
        tabPanel("Curved Lines", align= "centre",
          column(width = 12, align = 'centre' ,
                 # plotOutput("curvedMap")
                 leafletOutput("curvedMap", height = "600px")
                 )
          ),
        tabPanel('Others ')
      )
    )
)

# Server logic
server <- function(input, output) {
  
  # Load data
  popup_df <- read_csv("PopupDB_FromTableau2.csv")
  unemployment_df <- read_csv("Unemployment_cleaned.csv")
  merged_df <- merge(popup_df, unemployment_df, by.x="Website_country", by.y="Country Name", all.x=FALSE, all.y=FALSE)
  country_counts <- merged_df %>%
    group_by(Website_country, Phone_country) %>%
    summarise(Count = n())
  country_counts_diff <- country_counts %>% filter(Website_country != Phone_country)
  
  # Prepare world data
  world <- st_as_sf(maps::map('world', plot = FALSE, fill = TRUE))
  world_valid <- st_make_valid(world)
  
  # Calculate centroids
  country_centroids <- st_centroid(world_valid)
  country_centroids_df <- data.frame(st_coordinates(st_geometry(country_centroids)))
  names(country_centroids_df) <- c("lon", "lat")
  country_centroids_df <- cbind(country_centroids_df, country = world$ID)
  
  # Join data with centroids
  data <- country_counts %>%
    left_join(country_centroids_df, by = c("Website_country" = "country")) %>%
    rename(website_lon = lon, website_lat = lat) %>%
    left_join(country_centroids_df, by = c("Phone_country" = "country")) %>%
    rename(phone_lon = lon, phone_lat = lat)

  adjusted_data <- reactive({
    data 
      # mutate(
      #   phone_lon = ifelse(website_lon == phone_lon & website_lat == phone_lat, phone_lon + 0.5, phone_lon),
      #   phone_lat = ifelse(website_lon == phone_lon & website_lat == phone_lat, phone_lat + 0.5, phone_lat)
      # )
  })
  

  output$curvedMap <- renderLeaflet({
    
    
    curve_arrow <- function(lon1, lat1, lon2, lat2, curvature = 0.1) {
      mid_point <- geosphere::gcIntermediate(c(lon1, lat1), c(lon2, lat2), n = 50, addStartEnd = TRUE)
      x <- mid_point[, 1]
      y <- mid_point[, 2]
      mx <- mean(x)
      my <- mean(y)
      x <- x + curvature * (my - y)
      y <- y + curvature * (x - mx)
      data.frame(lon = x, lat = y)
    }
    
  
    # Create a basic leaflet map
    m <- leaflet() %>%
      # addTiles() %>% 
      # addProviderTiles(providers$OpenStreetMap) %>%
      # addProviderTiles(providers$Esri.NatGeoWorldMap)%>%
      addProviderTiles(providers$Stadia.AlidadeSmooth) %>%
      # addProviderTiles(providers$CartoDB.Positron) %>%
      # addPolylines(data = curve_arrow(adjusted_data$website_lon, adjusted_data$website_lat, adjusted_data$phone_lon, adjusted_data$phone_lat))%>% # Add a basic OSM map background
      setView(zoom = 2.5, lat = 51 , lng = 10 )
    
    # Add the world polygons
    m <- m %>% addPolygons(data = world, fillColor = "white", color = "black", weight = 1)
    
    # Add the curved lines
    for(i in 1:nrow(adjusted_data())){
      lat_from <- adjusted_data()$website_lat[i]
      lon_from <- adjusted_data()$website_lon[i]
      lat_to <- adjusted_data()$phone_lat[i]
      lon_to <- adjusted_data()$phone_lon[i]
      
      m <- m %>% addPolylines(
        lng = c(lon_from, (lon_from + lon_to)/2 + 0.1*(lon_to - lon_from), lon_to),
        lat = c(lat_from, (lat_from + lat_to)/2 + 0.1*(lat_to - lat_from), lat_to),
        color = "red",
        weight = (adjusted_data()$Count[i] / max(adjusted_data()$Count)) * 500
      )
    }
    
    return(m)
  })
  
  
}

# Run the app
shinyApp(ui, server)
