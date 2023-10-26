
# install.packages(c("sf", "tmap", "rnaturalearth", "rnaturalearthdata"))

library(shiny)
library(dplyr)
library(tidyr)
library(lubridate)
library(sf)
library(tmap)
library(rnaturalearth)

tmap_options(check.and.fix = TRUE)


popup_df <- read_csv("PopupDB_FromTableau2.csv")
unemployment_df <- read_csv("Unemployment_cleaned.csv")


merged_df <- merge(popup_df, unemployment_df, by.x="Website_country", by.y="Country Name", all.x=FALSE, all.y=FALSE)

# for the graph of the choropleth map 

merged_df$Date <- year(dmy_hms(merged_df$Date))

scams_count_df <- merged_df %>%
  group_by(Website_country, Date) %>%
  summarise(Count = n(), )

scams_difference <- unique(scams_count_df %>%
  spread(key = Date,  value = Count)%>% 
  group_by(Website_country) %>%
  reframe(scams_Difference = (`2021`-`2020`)/`2020`)%>%
  drop_na(scams_Difference) )

unemp_difference <- unique(merged_df %>%
  spread(key = Year, value = Unemployment_percentage) %>%
  group_by(Website_country) %>%
  reframe(unemp_Difference = `2020` - `2021`))


pivot_count_df <- inner_join(scams_difference, unemp_difference, by="Website_country") %>%
  drop_na()

world <- ne_countries(scale = "medium", returnclass = "sf")

merged_map_data <- merge(world, pivot_count_df, by.x="name", by.y="Website_country" , all.x = T)


gradient_palette <- colorRampPalette(c("green", "red"))

tm_basemap("OpenStreetMap")+
tm_shape(merged_map_data) + 
  tm_polygons("unemp_Difference", title="Unemployment change from 2020 to 2021 %",
              palette = gradient_palette(100),  # Here 100 represents the number of colors in the gradient
              midpoint = 0,  
              style = "cont") + 
  tm_layout(title="Year-over-Year Unemployment Percentage by Country", 
            title.position = c("center", "top"))


# Shiny app
shinyApp(
  # UI
  ui = fluidPage(
    titlePanel("Year-over-Year Unemployment Percentage by Country"),
    
      column(align ='center', width = 12, plotOutput("choroplethMap", height = "700px")), 
      column(align = "center", width = 12, sliderInput("countRange", 
                             "Select # Scams Range:", 
                             min = round( min(pivot_count_df$scams_Difference) , 2), 
                             max = round(max(pivot_count_df$scams_Difference), 2)+0.1, 
                             value = c(min(pivot_count_df$scams_Difference), max(pivot_count_df$scams_Difference)),
                             step = 0.5
      ) )
    
    
  ),
  
  # Server
  server = function(input, output) {
    
    output$choroplethMap <- renderPlot({
      
      # Filter data based on the selected count range
      filtered_data <- pivot_count_df %>%
        filter(scams_Difference >= input$countRange[1] & scams_Difference <= input$countRange[2])
      
      # Merge the data with the world map
      
      merged_map_data <- merge(world, filtered_data, by.x="name", by.y="Website_country" , all.x = T)
      merged_map_data$unemp_Difference[is.na(merged_map_data$unemp_Difference)] <- NA
      merged_map_data <- st_transform(merged_map_data, 3857)  # Transform to Web Mercator projection
      merged_map_data <- st_transform(merged_map_data, "+proj=robin +lon_0=0")
      
      # Plot
      tm_basemap("Stamen.Terrain")+
      tm_shape(merged_map_data) + 
      tm_polygons("unemp_Difference", title="Unemployment change from 2020 to 2021 %",
                    palette = gradient_palette(100),  # Here 100 represents the number of colors in the gradient
                    midpoint = 0,
                    style = "cont" , 
                    na.color = 'white') + 
        tm_layout(title="Year-over-Year Unemployment Percentage by Country")
      
    })
  }
)

