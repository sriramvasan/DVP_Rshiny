library(jsonlite)
x <- toJSON(pivot_count_df)
cat(x)