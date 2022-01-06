# This file takes the ECOSTRESS data and resamples it to the consistent CA grid. 
# It also creates an accompanying brick of uncertainties. 
# If the uncertainties are missing, that ET tif is discarded. 

# Anna Boser November 5, 2021

library(here)
library(raster)
library(dplyr)
library(rgdal)
library(data.table)
library(stringr)
library(lubridate)
library(sf)

CA_grid <- raster(here("data", "intermediate", "CA_grid.tif"))
CA <- st_read(here("data", "raw", "shapefiles", "california", "california.shp")) %>% st_transform(st_crs(CA_grid))

# get the ET file names
files <- list.files(here::here("data", 
                               "raw", 
                               "ECOSTRESS"), 
                    full.names = TRUE) %>% unique() #get rid of any duplicates

# get the different image timestamps
timestamps <- str_extract(files, regex('(?<=_doy)[0-9]*(?=_aid0001.tif)'))
names(timestamps) <- files #in order to find the files based on the timestamp

# get the list of timestamps we will consider
unique_timestamps <- unique(timestamps)
# remove those that don't have uncertainties
unique_timestamps <- unique_timestamps[unique_timestamps %in% timestamps[duplicated(timestamps)]]

# remove 2021
unique_timestamps <- unique_timestamps[substr(unique_timestamps, 1, 4) != "2021"]
length(unique_timestamps)

# define read and resample function
read_resample <- function(file){
  raster <- raster(file)
  raster <- raster(file) %>% resample(CA_grid, method = "bilinear")
  return(raster)
}

# define function that saves the tifs for the files with a certain timestamp
process <- function(timestamp){
  print(paste("New timestamp:", timestamp))
  
  timestamp_files <- names(timestamps[timestamps == timestamp])
  
  # get the ET and the sd
  ET_file <- str_subset(timestamp_files, regex('(?<=PT_JPL_)ETinst(?=_doy)'))
  sd_file <- str_subset(timestamp_files, regex('(?<=PT_JPL_)ETinstUncertainty(?=_doy)'))
  
  # ascertain that the timestamp has both ET and ETsd
  if (length(ET_file) != 1){
    stop("length(ET_file) != 1; aka you don't have an ET file for this timestamp (or you have multiple)")
  } else if (length(sd_file) != 1){
    stop("length(sd_file) != 1; aka you don't have an uncertainty file for this timestamp (or you have multiple)")
  }
  
  # read, resample, and write
  print("Resampling ET raster")
  ET_raster <- read_resample(ET_file)
  print("Writing ET raster")
  writeRaster(ET_raster, here("data", "intermediate", "ECOSTRESS", "ET", paste0(timestamp, ".tif")), "GTiff", overwrite=TRUE)
  
  rm(ET_file, ET_raster)
  
  print("Resampling sd raster")
  sd_raster <- read_resample(sd_file)
  print("Writing sd raster")
  writeRaster(sd_raster, here("data", "intermediate", "ECOSTRESS", "ET_sd", paste0(timestamp, ".tif")), "GTiff", overwrite=TRUE)
  
  rm(sd_file, sd_raster)
}

# make the new directories
dir.create(here("data", "intermediate", "ECOSTRESS"))
dir.create(here("data", "intermediate", "ECOSTRESS", "ET"))
dir.create(here("data", "intermediate", "ECOSTRESS", "ET_sd"))

# for loop so you can keep track of when it blew up
for (i in 152:length(unique_timestamps)){
  print(paste("On timestamp number", i))
  time <- Sys.time()
  process(unique_timestamps[i])
  print(paste("Time elapsed for this timestamp:", Sys.time() - time))
}

