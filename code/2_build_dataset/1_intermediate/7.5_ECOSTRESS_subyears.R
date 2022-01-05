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

# for each month group (by year), read in and stack the files, and take the average 
read_average_write <- function(mgroup, year){
  # pick only the datasets for that year and from the right monthgroup
  files <- files[year(date) == year & monthgroup == mgroup]
  
  # read in all files and take their average. Pray it doesn't break!!
  rasters <- lapply(files, raster)
  
  # make a brick
  brick <- brick(rasters)
  
  # save this brick in case you want it later
  
  
  # average
  mean <- mean(brick, na.rm = TRUE)
  
}

# combine across years