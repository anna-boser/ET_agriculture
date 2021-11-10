# This file takes the ECOSTRESS data, resamples it to the consistent CA grid, and stacks it. 

# It also creates an accompanying brick of uncertainties. 
# If the uncertainties are missing, then that layer is simply NA. 

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

#separate ET estimates from uncertainty files
ET_files <- str_subset(files, regex('(?<=PT_JPL_)ETinst(?=_doy)'))
# Uncertainty_files <- str_subset(files, regex('(?<=PT_JPL_)ETinstUncertainty(?=_doy)'))

# get the different image dates
dates <- str_extract(ET_files, regex('(?<=_doy)[0-9]*(?=_aid0001.tif)'))
names(dates) <- ET_files
sort(dates)

# remove 2021
dates <- dates[substr(dates, 1, 4) != "2021"]
length(dates)

process <- function(date){
  print(paste("New date:", date))
  
  file <- names(dates[dates == date])
  
  if (!file.exists(file)){
    raster <- CA_grid # this is an empty grid
    names(raster) <- date
    return(raster)
  } else {
    raster <- raster(file) %>% resample(CA_grid, method = "bilinear")
    names(raster) <- date
    return(raster)
  }
}

################################################################################
################################################################################
# This code breaks up the code directly below in order to deal with the fact that it needs a lot of memory. 

# read in, change units, and resample all ET rasters
print("processing ET rasters")

for (i in 4){
  print(i)
  from <- (i-1)*50 + 1
  to <- min(i*50, length(dates))
  
  ET_rasters <- lapply(dates[from:to], process)
  ET_brick <- brick(ET_rasters)
  writeRaster(ET_brick, here("data", "intermediate", "ECOSTRESS", paste0("ETinst_OGunits_", i, ".tif")), "GTiff", overwrite=TRUE)
  
  rm(ET_rasters)
  rm(ET_brick)
}
