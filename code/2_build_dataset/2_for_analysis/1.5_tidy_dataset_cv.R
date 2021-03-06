# This script takes the non-tidy full datasets created in 1_combine_intermediate.py 
# and makes them tidy for use in the random forest model. 

# Anna Boser
# Jan 13, 2022

library(here)
library(data.table)
library(dplyr)
library(tidyr)
library(suncalc)

# function to tidy data
tidy <- function(data){
  ET <- data[,15:20]
  data <- data[,1:14]
  clean <- pivot_longer(data, cols = paste0("PET", 0:5), names_to = "monthgroup", names_prefix = "PET", values_to = "PET")
  ET <- pivot_longer(ET, cols = paste0("ET", 0:5), names_to = "monthgroup", names_prefix = "ET", values_to = "ET")
  clean$ET <- ET$ET
  clean <- clean[!is.na(clean$ET),] #filter out missing ET values
  return(clean)
}

# function to change ET units to mm
to_mm <- function(watts_m2, date){ #watts = J/s
  hours_of_daylight <- getSunlightTimes(date, 37.9833, -121.8677)$sunset - 
    getSunlightTimes(date, 37.9833, -121.8677)$sunrise # lat and lon are SJ valley coordinates from google maps. timezone not specified since we only care about the difference
  hours_of_daylight <- as.numeric(hours_of_daylight)
  kg = watts_m2*hours_of_daylight*3600*(1/2257)*(1/1000) # J/s * hours (h) * seconds in an hour (s/h) * latent heat of fusion (g/J) * conversion to kg AKA mm over a m2 (kg/g)
}

# dates picked to minimize problems with Jensen's inequality: 
# 2: June 1
# 3: August 15
# 4: October 15

# tidy ag
data <- fread(here("data", "for_analysis", "agriculture_not_tidy_cv.csv"))
data <- tidy(data)
fwrite(data, here("data", "for_analysis", "agriculture_cv.csv"))

# only growing season
data <- dplyr::filter(data, monthgroup %in% 2:4)
data$agriculture <- NULL
data$counterfactual <- NULL
fwrite(data, here("data", "for_analysis", "agriculture_cv_gs.csv"))

# change ET units to mm and remove NA data
data <- filter(data, ET>=0)
data$ET <- ifelse(data$monthgroup == 2, to_mm(data$ET, as.Date("2019/06/01")), data$ET)
data$ET <- ifelse(data$monthgroup == 3, to_mm(data$ET, as.Date("2019/08/15")), data$ET)
data$ET <- ifelse(data$monthgroup == 4, to_mm(data$ET, as.Date("2019/10/15")), data$ET)
fwrite(data, here("data", "for_analysis", "agriculture_cv_gs_mm.csv"))

#tidy counterfactual
data <- fread(here("data", "for_analysis", "counterfactual_not_tidy_cv.csv"))
data <- tidy(data)
fwrite(data, here("data", "for_analysis", "counterfactual_cv.csv"))

# only growing season
data <- dplyr::filter(data, monthgroup %in% 2:4)
data$agriculture <- NULL
data$counterfactual <- NULL
fwrite(data, here("data", "for_analysis", "counterfactual_cv_gs.csv"))

# change ET units to mm
data <- filter(data, ET>=0)
data$ET <- ifelse(data$monthgroup == 2, to_mm(data$ET, as.Date("2019/06/01")), data$ET)
data$ET <- ifelse(data$monthgroup == 3, to_mm(data$ET, as.Date("2019/08/15")), data$ET)
data$ET <- ifelse(data$monthgroup == 4, to_mm(data$ET, as.Date("2019/10/15")), data$ET)
fwrite(data, here("data", "for_analysis", "counterfactual_cv_gs_mm.csv"))

# After visually inspecting the simulated counterfactual using the above dataset, 
# it became clear that certain locations were likely contaminated and were irrigated. 
# Therefore, here we screen for locations that are likely not natural land and get rid of them. 

data <- fread(here("data/for_analysis/counterfactual_cv_gs_mm.csv"))

# remove monthgroups
data <- pivot_wider(data, names_from = c(monthgroup), values_from = c(ET, PET))

data$ET <- rowMeans(select(data, ET_2, ET_3, ET_4), na.rm = FALSE)
data$PET <- rowMeans(select(data, PET_2, PET_3, PET_4), na.rm = FALSE)

data <- data %>% select(-ET_2, -ET_3, -ET_4, -PET_2, -PET_3, -PET_4)

# remove any NA values
data <- filter(data, !(is.na(ET)))

# inspect <- filter(data, ET>2.5)

# inspect %>%
#   ggplot() + 
#   geom_point(aes(x = x, y = y, color = ET), size = .1) + 
#   scale_color_gradientn(name="ET (mm/day)", colours = c("darkgoldenrod4", "darkgoldenrod2", "khaki1", "lightgreen", "turquoise3", "deepskyblue3", "mediumblue", "navyblue", "midnightblue", "black")) + 
#   theme_void()

# After visual inspection, anything above 4 looks like it could plausibly be irrigated. 
# This represents .1% of the data, so we feel that it is unlikely that we are biasing the natural counterfactual downward. 

# identify these locations and remove them from the dataset
loc <- paste(filter(data, ET < 4)$x, filter(data, ET < 4)$y)

data <- fread(here("data/for_analysis/counterfactual_cv_gs_mm.csv"))
data <- filter(data, paste(data$x, data$y) %in% loc)

fwrite(data, here("data", "for_analysis", "counterfactual_cv_gs_mm<4.csv"))



