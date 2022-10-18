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
  data$agriculture <- NULL
  data$counterfactual <- NULL
  data$fveg <- NULL
  data$cpad <- NULL
  data$cpad_fveg <- NULL
  data$cdl_fveg <- NULL
  ET <- data[,17:22]
  data <- data[,1:16]
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

big_tide <- function(inloc, outloc, outloc_gs_mm){
  #tidy counterfactual
  data <- fread(inloc)
  data <- tidy(data)
  fwrite(data, outloc)
  
  # only growing season
  data <- dplyr::filter(data, monthgroup %in% 2:4)
  
  # change ET units to mm
  data <- filter(data, ET>=0)
  data$ET <- ifelse(data$monthgroup == 2, to_mm(data$ET, as.Date("2019/06/01")), data$ET)
  data$ET <- ifelse(data$monthgroup == 3, to_mm(data$ET, as.Date("2019/08/15")), data$ET)
  data$ET <- ifelse(data$monthgroup == 4, to_mm(data$ET, as.Date("2019/10/15")), data$ET)
  fwrite(data, outloc_gs_mm)
}

# dates picked to minimize problems with Jensen's inequality: 
# 2: June 1
# 3: August 15
# 4: October 15

# ag
big_tide(inloc = here("data", "for_analysis", "agriculture_not_tidy_cv.csv"), 
         outloc = here("data", "for_analysis", "agriculture_cv.csv"), 
         outloc_gs_mm = here("data", "for_analysis", "agriculture_cv_gs_mm.csv")
)

# cdl (nlcd) (original "counterfactual")
big_tide(inloc = here("data", "for_analysis", "counterfactual_not_tidy_cv.csv"), 
         outloc = here("data", "for_analysis", "counterfactual_cv.csv"), 
         outloc_gs_mm = here("data", "for_analysis", "counterfactual_cv_gs_mm.csv")
)

#fveg
big_tide(inloc = here("data", "for_analysis", "fveg_not_tidy_cv.csv"), 
         outloc = here("data", "for_analysis", "fveg_cv.csv"), 
         outloc_gs_mm = here("data", "for_analysis", "fveg_cv_gs_mm.csv")
)

#cpad
big_tide(inloc = here("data", "for_analysis", "cpad_not_tidy_cv.csv"), 
         outloc = here("data", "for_analysis", "cpad_cv.csv"), 
         outloc_gs_mm = here("data", "for_analysis", "cpad_cv_gs_mm.csv")
)

#cpad_fveg
big_tide(inloc = here("data", "for_analysis", "cpad_fveg_not_tidy_cv.csv"), 
         outloc = here("data", "for_analysis", "cpad_fveg_cv.csv"), 
         outloc_gs_mm = here("data", "for_analysis", "cpad_fveg_cv_gs_mm.csv")
)

#cdl_fveg
big_tide(inloc = here("data", "for_analysis", "cdl_fveg_not_tidy_cv.csv"), 
         outloc = here("data", "for_analysis", "cdl_fveg_cv.csv"), 
         outloc_gs_mm = here("data", "for_analysis", "cdl_fveg_cv_gs_mm.csv")
)

# ####################################################################################
# # This code is to remove outliers. 
# # After visually inspecting the simulated counterfactual (cdl) using the above dataset, 
# # it became clear that certain locations were likely contaminated and were irrigated. 
# # Therefore, here we screen for locations that are likely not natural land and get rid of them. 
# 
# data <- fread(here("data/for_analysis/counterfactual_cv_gs_mm.csv"))
# 
# # remove monthgroups
# data <- pivot_wider(data, names_from = c(monthgroup), values_from = c(ET, PET))
# 
# data$ET <- rowMeans(select(data, ET_2, ET_3, ET_4), na.rm = FALSE)
# data$PET <- rowMeans(select(data, PET_2, PET_3, PET_4), na.rm = FALSE)
# 
# data <- data %>% select(-ET_2, -ET_3, -ET_4, -PET_2, -PET_3, -PET_4)
# 
# # remove any NA values
# data <- filter(data, !(is.na(ET)))
# 
# # inspect <- filter(data, ET>2.5)
# 
# # library(ggplot2)
# # inspect %>%
# #   ggplot() +
# #   geom_point(aes(x = x, y = y, color = ET), size = .1) +
# #   scale_color_gradientn(name="ET (mm/day)", colours = c("darkgoldenrod4", "darkgoldenrod2", "khaki1", "lightgreen", "turquoise3", "deepskyblue3", "mediumblue", "navyblue", "midnightblue", "black")) +
# #   theme_void()
# 
# # After visual inspection, anything above 4 looks like it could plausibly be irrigated. 
# # This represents .1% of the data, so we feel that it is unlikely that we are biasing the natural counterfactual downward. 
# 
# # identify these locations and remove them from the dataset
# loc <- paste(filter(data, ET < 4)$x, filter(data, ET < 4)$y)
# 
# data2 <- fread(here("data/for_analysis/counterfactual_cv_gs_mm.csv"))
# data2 <- filter(data2, paste(data2$x, data2$y) %in% loc)
# 
# fwrite(data2, here("data", "for_analysis", "counterfactual_cv_gs_mm<4.csv"))
# 
# # anything above 4.5; .03%
# loc <- paste(filter(data, ET < 4.5)$x, filter(data, ET < 4.5)$y)
# 
# data2 <- fread(here("data/for_analysis/counterfactual_cv_gs_mm.csv"))
# data2 <- filter(data2, paste(data2$x, data2$y) %in% loc)
# 
# fwrite(data2, here("data", "for_analysis", "counterfactual_cv_gs_mm<4.5.csv"))
# 
# # anything above 5; .005% of the data
# loc <- paste(filter(data, ET < 5)$x, filter(data, ET < 5)$y)
# 
# data2 <- fread(here("data/for_analysis/counterfactual_cv_gs_mm.csv"))
# data2 <- filter(data2, paste(data2$x, data2$y) %in% loc)
# 
# fwrite(data2, here("data", "for_analysis", "counterfactual_cv_gs_mm<5.csv"))
