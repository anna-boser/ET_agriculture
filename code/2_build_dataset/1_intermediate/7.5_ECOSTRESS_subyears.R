# This file breaks the ECOSTRESS data into into the subyear groups I'm interested in, 
# and gets an average standard grid for each time period

# Anna Boser January 5, 2021

library(here)
library(raster)
library(dplyr)
library(rgdal)
library(data.table)
library(stringr)
library(lubridate)
library(sf)

# get a list of the files 
files <- list.files(here::here("data", 
                               "intermediate", 
                               "ECOSTRESS", 
                               "ET"), 
                    full.names = TRUE) %>% unique() #get rid of any duplicates

# get the date for each timestamp
timestamps <- list.files(here::here("data", 
                               "intermediate", 
                               "ECOSTRESS", 
                               "ET"), 
                    full.names = FALSE) %>% 
  unique() %>% #get rid of any duplicates 
  substr(1, 13) # only keep the timestamps

date <- as.Date(timestamps, "%Y%j%H%M%S")

# assign the date to a month group (by year)
# in this function, monthgroup 0 is the one starting on January 15. 
# There are 0-5 monthgroups. 
monthgroup <- function(date){
  date <- date - 14
  monthgroup <- month(date) - month(date)%%2 
  return(monthgroup)
}

monthgroup <- sapply(date, monthgroup)

dir.create(here("data", "intermediate", "ECOSTRESS", "ET_brick"))
dir.create(here("data", "intermediate", "ECOSTRESS", "ET_mean"))
dir.create(here("data", "intermediate", "ECOSTRESS", "ET_mean_by_year"))

# for each month group (by year), read in and stack the files, and take the average 
read_average_write <- function(mgroup, year){
  
  time <- Sys.time() #keep track of how long this takes
  
  # pick only the datasets for that year and from the right monthgroup
  print(paste("group:", mgroup, "; year:", year))
  files <- files[year(date) == year & monthgroup == mgroup]
  print(paste("Number of files in this month group:", length(files)))
  
  # read in all files and take their average. Pray it doesn't break!!
  print("reading in rasters")
  rasters <- lapply(files, raster)
  
  # make a brick
  print("making a brick")
  brick <- brick(rasters)
  rm(rasters)
  
  # save this brick in case you want it later
  writeRaster(brick, here("data", "intermediate", "ECOSTRESS", "ET_brick", paste0(mgroup, "-", plotyear, ".tif")), "GTiff", overwrite=TRUE)
  
  # average
  mean <- mean(brick, na.rm = TRUE)
  rm(brick)
  
  # save the mean
  writeRaster(mean, here("data", "intermediate", "ECOSTRESS", "ET_mean_by_year", paste0(mgroup, "-", plotyear, ".tif")), "GTiff", overwrite=TRUE)
  
  print(paste("Time elapsed for this group and year:", Sys.time() - time))
  
  return(mean)
}

# take the average for a group across years
avg_across_years <- function(mgroup){
  
  print(paste("doing group", mgroup))
  
  mean_2019 <- read_average_write(mgroup, 2019)
  mean_2020 <- read_average_write(mgroup, 2020)
  
  print("bricking both years together")
  brick <- brick(list(mean2019, mean2020))
  rm(mean_2019, mean_2020)
  
  # average the two together
  mean <- mean(brick, na.rm = TRUE)
  rm(brick)
  
  print(paste("saving mean of group", mygroup))
  writeRaster(mean, here("data", "intermediate", "ECOSTRESS", "ET_mean", paste0(mgroup, ".tif")), "GTiff", overwrite=TRUE)
  return(mean)
}

g0 <- avg_across_years(0)
g1 <- avg_across_years(1)
g2 <- avg_across_years(2)
g3 <- avg_across_years(3)
g4 <- avg_across_years(4)
g5 <- avg_across_years(5)

brick <- brick(list(g0, g1, g2, g3, g4, g5))
rm(g0, g1, g2, g3, g4, g5)

mean <- mean(brick, na.rm = TRUE)
rm(brick)

writeRaster(mean, here("data", "intermediate", "ECOSTRESS", "compete_mean.tif"), "GTiff", overwrite=TRUE)

