# This script takes the non-tidy full datasets created in 1_combine_intermediate.py 
# and makes them tidy for use in the random forest model. 

# Anna Boser
# Jan 13, 2022

library(here)
library(data.table)
library(dplyr)
library(tidyr)


tidy <- function(data){
  ET <- data[,15:20]
  data <- data[,1:14]
  clean <- pivot_longer(data, cols = paste0("PET", 0:5), names_to = "monthgroup", names_prefix = "PET", values_to = "PET")
  ET <- pivot_longer(ET, cols = paste0("ET", 0:5), names_to = "monthgroup", names_prefix = "ET", values_to = "ET")
  clean$ET <- ET$ET
  clean <- clean[!is.na(clean$ET),] #filter out missing ET values
  return(clean)
}

# tidy ag
data <- fread(here("data", "for_analysis", "agriculture_not_tidy_cv.csv"))
data <- tidy(data)
fwrite(data, here("data", "for_analysis", "agriculture_cv.csv"))

#tidy counterfactual
data <- fread(here("data", "for_analysis", "counterfactual_not_tidy_cv.csv"))
data <- tidy(data)
fwrite(data, here("data", "for_analysis", "counterfactual_cv.csv"))
