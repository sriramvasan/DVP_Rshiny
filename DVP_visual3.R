# library(jsonlite)
# x <- toJSON(pivot_count_df)
# cat(x)

# install.packages("networkD3")

library(shiny)
library(dplyr)
library(tidyr)
library(lubridate)
library(sf)
library(tmap)
library(rnaturalearth)
library(networkD3)

tmap_options(check.and.fix = TRUE)


popup_df <- read_csv("PopupDB_FromTableau2.csv")
unemployment_df <- read_csv("Unemployment_cleaned.csv")


merged_df <- merge(popup_df, unemployment_df, by.x="Website_country", by.y="Country Name", all.x=FALSE, all.y=FALSE)

# Define UI
ui <- fluidPage(
  titlePanel("Sankey Diagram"),
  column(offset = 2,  width = 8,
         sankeyNetworkOutput("sankeyPlot")
         ),
  tags$style(type="text/css", "#sankeyPlot {overflow: auto;}"),
  tags$script('
    $(document).on("mousemove", ".link", function(e) {
      var from = $(this).data("source");
      var to = $(this).data("target");
      $("body").tooltip({
        placement: "auto",
        title: "From: " + from + "<br>To: " + to,
        html: true
      });
      $(this).tooltip("show");
    });

    $(document).on("mouseout", ".link", function() {
      $(this).tooltip("destroy");
    });
  ')
)

# Define server logic
server <- function(input, output) {
  output$sankeyPlot <- renderSankeyNetwork({
    
    country_counts <- merged_df %>%
      group_by(Website_country, Phone_country) %>%
      summarise(Count = n())
    
    country_counts_diff <- country_counts %>% filter(Website_country != Phone_country)
    country_counts_diff <-  country_counts_diff %>% filter( Count > 10 )
    
    # Prepare data for Sankey diagram
    nodes <- data.frame(name = unique(c(as.character(country_counts_diff$Website_country), as.character(country_counts_diff$Phone_country))))
    links <- country_counts_diff %>%
      left_join(data.frame(name = nodes$name, id = 0:(nrow(nodes)-1)), by = c("Phone_country" = "name")) %>%
      rename(source = id) %>%
      left_join(data.frame(name = nodes$name, id = 0:(nrow(nodes)-1)), by = c("Website_country" = "name")) %>%
      rename(target = id) %>%
      select(source, target, Count)
    
    # Add tooltips
    # links$tooltip <- paste0("From: ", nodes$name[links$source + 1], "<br>To: ", nodes$name[links$target + 1])
    
    # Create a Sankey diagram
    sankey <- sankeyNetwork(Links = links, Nodes = nodes, Source = "source",
                            Target = "target", Value = "Count", NodeID = "name",
                            units = " ", fontSize = 12, nodeWidth = 15)
                            # linkGroup = "tooltip", fontFamily = "sans-serif",
                            # tooltip = TRUE)
    
    return(sankey)
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

