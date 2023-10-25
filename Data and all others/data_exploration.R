
library(dplyr)

df <- read.csv("PopupDB.csv")


View(df)


head(df)

names(df)

dim(df)
# has 11375 rows


summary(df)
names(df)

# the columns in the dataset are  
# "UID"       "Domain"    "Url"       "Number"    "Host"      "Country"   "City"      "IP"        "ASN"       "Latitude" 
# "Longitude" "Hash"      "Date"      "Mail"



# exploring UID 
# The UID is the unique identifier of the dataset 
length( unique( df$UID) )



# exploring Domain 

length(unique(  ))

doms <- df$Domain
