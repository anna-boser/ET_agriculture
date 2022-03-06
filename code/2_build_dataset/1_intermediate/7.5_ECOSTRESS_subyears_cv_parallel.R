# This file breaks the ECOSTRESS data into into the subyear groups I'm interested in, 
# and gets an average standard grid for each time period

# Anna Boser January 5, 2022

library(here)
library(raster)
library(dplyr)
library(rgdal)
library(data.table)
library(stringr)
library(lubridate)
library(sf)
library(parallel)

# get a list of the files 
files <- list.files(here::here("data", 
                               "intermediate", 
                               "ECOSTRESS_cv", 
                               "ET"), 
                    full.names = TRUE) %>% unique() #get rid of any duplicates

# get the date for each timestamp
timestamps <- list.files(here::here("data", 
                               "intermediate", 
                               "ECOSTRESS_cv", 
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
  monthgroup <- ((month(date)-1) - (month(date)-1)%%2)/2
  return(monthgroup)
}

monthgroup <- sapply(date, monthgroup)

dir.create(here("data", "intermediate", "ECOSTRESS_cv", "ET_brick"))
dir.create(here("data", "intermediate", "ECOSTRESS_cv", "ET_mean"))
dir.create(here("data", "intermediate", "ECOSTRESS_cv", "ET_mean_by_year"))

# for each month group (by year), read in and stack the files, and take the average 
read_average_write <- function(mgroup, year){
  
  time <- Sys.time() #keep track of how long this takes
  
  # pick only the datasets for that year and from the right monthgroup
  print(paste("group:", mgroup, "; year:", year))
  files <- files[year(date) == year & monthgroup == mgroup]
  print(paste("Number of files in this month group:", length(files)))
  
  if (length(files) != 0){
    # read in all files and take their average. Pray it doesn't break!!
    print("reading in rasters")
    rasters <- lapply(files, raster)
    
    # make a brick
    print("making a brick")
    brick <- brick(rasters)
    rm(rasters)
    
    # save this brick in case you want it later
    print("saving the brick")
    writeRaster(brick, here("data", "intermediate", "ECOSTRESS_cv", "ET_brick", paste0(mgroup, "-", year, ".tif")), "GTiff", overwrite=TRUE)
    
    # average
    print("taking the mean of the brick")
    mean <- mean(brick, na.rm = TRUE)
    rm(brick)
    
    # save the mean
    print("saving the mean")
    writeRaster(mean, here("data", "intermediate", "ECOSTRESS_cv", "ET_mean_by_year", paste0(mgroup, "-", year, ".tif")), "GTiff", overwrite=TRUE)
    
    print(paste("Time elapsed for this group and year:", Sys.time() - time))
    
    return(mean)
  } else {
    return(NULL)
  }
  
}

monthgroups <- 2:4

no_cores <- detectCores() - 1 # Calculate the number of cores
print(no_cores)
cl <- makeCluster(no_cores, type="FORK") # Initiate cluster
parLapply(cl, monthgroups, read_average_write, year = 2019)
parLapply(cl, monthgroups, read_average_write, year = 2020)
parLapply(cl, monthgroups, read_average_write, year = 2021)
stopCluster(cl)

# take the average for a group across years
avg_across_years <- function(mgroup){
  
  time <- Sys.time() #keep track of how long this takes

  print(paste("doing group", mgroup))

  print("bricking years together")
  # get a list of all the year rasters with that monthgroup
  brick <- brick(list(raster(here("data", "intermediate", "ECOSTRESS", "ET_mean_by_year", paste0(mgroup, "-2019.tif"))),
                      raster(here("data", "intermediate", "ECOSTRESS", "ET_mean_by_year", paste0(mgroup, "-2020.tif"))), 
                      raster(here("data", "intermediate", "ECOSTRESS", "ET_mean_by_year", paste0(mgroup, "-2021.tif")))))
  
  # average the two together
  mean <- mean(brick, na.rm = TRUE)
  rm(brick)

  print(paste("saving mean of group", mgroup))
  writeRaster(mean, here("data", "intermediate", "ECOSTRESS_cv", "ET_mean", paste0(mgroup, ".tif")), "GTiff", overwrite=TRUE)
  
  print(paste("Time elapsed for this group:", Sys.time() - time))
  
  return(mean)
}
####
no_cores <- detectCores() - 1 # Calculate the number of cores
print(no_cores)
cl <- makeCluster(no_cores, type="FORK") # Initiate cluster
parLapply(cl, monthgroups, avg_across_years)
stopCluster(cl)
