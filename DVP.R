# 
# # library(tidyverse)
# # library(lubridate)
# # library(igraph)
# # 
# # # Merge datasets
# # 
# # popup_df <- read_csv("PopupDB_FromTableau2.csv")
# # unemployment_df <- read_csv("Unemployment_cleaned.csv")
# # 
# # colnames(unemployment_df)
# # colnames(popup_df)
# # 
# # merged_df <- merge(popup_df, unemployment_df, by.x="Website_country", by.y="Country Name", all.x=FALSE, all.y=FALSE)
# # 
# # colnames(merged_df)
# # 
# # # Create an edge list based on successive IP addresses
# # edge_list <- data.frame(from = merged_df$Ip[-nrow(merged_df)], 
# #                         to = merged_df$Ip[-1])
# # 
# # # Create the graph
# # g <- graph_from_data_frame(edge_list, directed=FALSE)
# # 
# # # Remove self-links
# # g <- simplify(g, remove.multiple = FALSE, remove.loops = TRUE)
# # 
# # # Determine the degree of each vertex
# # deg <- degree(g)
# # 
# # # Define a threshold for "prominent connections"
# # threshold <- mean(deg) + 1.5 * sd(deg)  # For example, nodes with a degree greater than mean + 1.5 times the standard deviation
# # 
# # # Subset the graph to only include nodes with prominent connections
# # g_sub <- induced_subgraph(g, which(deg > threshold))
# # 
# # # Plot the subsetted graph
# # plot(g_sub, vertex.size=10, vertex.label.cex=1, edge.arrow.size=0.5, layout=layout_with_fr)
# # 
# # 
# # # Plot the graph
# # plot(g, vertex.size=10, vertex.label.cex=1, edge.arrow.size=0.5, layout=layout_with_fr)
# 
# 
# # Load necessary libraries
# library(shiny)
# library(tidyverse)
# library(lubridate)
# library(igraph)
# 
# popup_df <- read_csv("PopupDB_FromTableau2.csv")
# unemployment_df <- read_csv("Unemployment_cleaned.csv")
# 
# # colnames(unemployment_df)
# # colnames(popup_df)
# 
# merged_df <- merge(popup_df, unemployment_df, by.x="Website_country", by.y="Country Name", all.x=FALSE, all.y=FALSE)
# 
# 
# top_countries <- merged_df %>%
#   group_by(Website_country, Ip) %>%
#   tally() %>%
#   arrange(-n) %>%
#   slice_head(n = 10) 
# 
# # Define the Shiny app
# shinyApp(
#   
#   # UI for the Shiny app
#   ui = fluidPage(
#     titlePanel("Interactive Network Graph by Country"),
#     
#     sidebarLayout(
#       sidebarPanel(
#         selectInput("countryInput", 
#                     "Select a Country:", 
#                     choices = unique(merged_df$Website_country), 
#                     selected = "United States")
#       ),
#       
#       mainPanel(
#         plotOutput("networkPlot")
#       )
#     )
#   ),
#   
#   # Server logic
#   server = function(input, output) {
#     
#     output$networkPlot <- renderPlot({
#       
# 
#       # Filter data by selected country
#       filtered_data <- merged_df %>% filter(Website_country == merged_df$countryInput)
#       
#       # Create an edge list based on successive IP addresses in the filtered data
#       edge_list <- data.frame(from = filtered_data$Ip[-nrow(filtered_data)], 
#                               to = filtered_data$Ip[-1])
#       
#       # Create the graph
#       g <- graph_from_data_frame(edge_list, directed=FALSE)
#       
#       # Remove self-links
#       g <- simplify(g, remove.multiple = FALSE, remove.loops = TRUE)
#       
#       # Determine the degree of each vertex
#       deg <- degree(g)
#       
#       # Define a threshold for "prominent connections"
#       threshold <- mean(deg) + 1.5 * sd(deg)
#       
#       # Subset the graph to only include nodes with prominent connections
#       g_sub <- induced_subgraph(g, which(deg > threshold))
#       
#       # Plot the subsetted graph
#       plot(g_sub, vertex.size=10, vertex.label.cex=1, edge.arrow.size=0.5, layout=layout_with_fr)
#       
#     })
#     
#   }
#   
# )
# 
# 
# 

library(shiny)
library(tidyverse)
library(lubridate)
library(igraph)
library(plotly)

popup_df <- read_csv("PopupDB_FromTableau2.csv")
unemployment_df <- read_csv("Unemployment_cleaned.csv")

# colnames(unemployment_df)
# colnames(popup_df)

merged_df <- merge(popup_df, unemployment_df, by.x="Website_country", by.y="Country Name", all.x=FALSE, all.y=FALSE)

top_countries <- merged_df %>%
  group_by(Website_country, Ip, `Ip Orgs`) %>%
  tally() %>%
  arrange(-n) %>%
  slice_head(n = 10) %>% 
  filter(n >= 20)

# Define the Shiny app
shinyApp(
  
  # UI for the Shiny app
  ui = fluidPage(
    titlePanel("Interactive Network Graph by Country"),
    
    fluidRow(
      column(12, selectInput("countryInput", 
                             "Select a Country:", 
                             choices = unique(top_countries$Website_country), 
                             selected = "United States")),
      column(12, plotOutput("networkPlot"))
    )
    
    
    
  ),
  
  # Server logic
  server = function(input, output) {
    
    output$networkPlot <- renderPlot({
      
      
      # Filter data by selected country
      filtered_data <- merged_df %>% filter(Website_country == input$countryInput)
      
      # Create an edge list based on successive IP addresses in the filtered data
      edge_list <- data.frame(from = filtered_data$Ip[-nrow(filtered_data)], 
                              to = filtered_data$Ip[-1])
      
      colnames(filtered_data)
      
      # Create the graph
      g <- graph_from_data_frame(edge_list, directed=FALSE)
      
      # Remove self-links
      g <- simplify(g, remove.multiple = F, remove.loops = TRUE)
      
      # Extract organization information and create a color mapping
      org_colors <- rainbow(length(unique(filtered_data$`Ip Orgs`)))
      org_mapping <- setNames(org_colors, unique(filtered_data$`Ip Orgs`))
      
      ip_to_org <- setNames(top_countries$`Ip Orgs`, top_countries$Ip)
      V(g)$color <- org_mapping[ip_to_org[V(g)$name]]
      
      # Determine the degree of each vertex
      deg <- degree(g)
      
      # Define a threshold for "prominent connections"
      threshold <- mean(deg) + 0.75 * sd(deg)
      
      # Subset the graph to only include nodes with prominent connections
      g_sub <- induced_subgraph(g, which(deg > threshold))
      
      # Plot the subsetted graph
      plot(g_sub, vertex.size=10, vertex.label.cex=1, edge.arrow.size=0.5, layout=layout_with_fr)
      
      
      legend("bottomleft", legend = names(org_mapping), fill = org_mapping, cex = 0.7, title = "Organizations")
      
    })
    
  }
  
)



