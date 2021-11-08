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

write.csv(as.character(as.Date(dates, "%Y%j%H%M%S")), here("data", "intermediate", "ECOSTRESS", "dates.csv"))

# read in, change units, and resample all ET rasters
print("processing ET rasters")
ET_rasters <- lapply(dates[1:floor(length(dates)/4)], process)
# make a brick
ET_brick <- brick(ET_rasters)
#save as geotiff
dir.create(here("data", "intermediate", "ECOSTRESS"))
writeRaster(ET_brick, here("data", "intermediate", "ECOSTRESS", "ETinst_OGunits_Q1.tif"), "GTiff", overwrite=TRUE)

rm(ET_rasters)
rm(ET_brick)

# read in, change units, and resample all ET rasters
print("processing ET rasters")
ET_rasters <- lapply(dates[(floor(length(dates)/4) + 1):(floor(length(dates)/2))], process)
# make a brick
ET_brick <- brick(ET_rasters)
#save as geotiff
dir.create(here("data", "intermediate", "ECOSTRESS"))
writeRaster(ET_brick, here("data", "intermediate", "ECOSTRESS", "ETinst_OGunits_Q2.tif"), "GTiff", overwrite=TRUE)

rm(ET_rasters)
rm(ET_brick)

# read in, change units, and resample all ET rasters
print("processing ET rasters")
ET_rasters <- lapply(dates[(floor(length(dates)/2) + 1):floor(3*length(dates)/4)], process)
# make a brick
ET_brick <- brick(ET_rasters)
#save as geotiff
dir.create(here("data", "intermediate", "ECOSTRESS"))
writeRaster(ET_brick, here("data", "intermediate", "ECOSTRESS", "ETinst_OGunits_Q3.tif"), "GTiff", overwrite=TRUE)

rm(ET_rasters)
rm(ET_brick)

# read in, change units, and resample all ET rasters
print("processing ET rasters")
ET_rasters <- lapply(dates[(floor(3*length(dates)/4)+1):length(dates)], process)
# make a brick
ET_brick <- brick(ET_rasters)
#save as geotiff
dir.create(here("data", "intermediate", "ECOSTRESS"))
writeRaster(ET_brick, here("data", "intermediate", "ECOSTRESS", "ETinst_OGunits.tif"), "GTiff", overwrite=TRUE)

rm(ET_rasters)
rm(ET_brick)

ET_brick <- ET_brick(list(raster(writeRaster(here("data", "intermediate", "ECOSTRESS", "ETinst_OGunits_Q1.tif"), "GTiff")), 
                          raster(writeRaster(here("data", "intermediate", "ECOSTRESS", "ETinst_OGunits_Q2.tif"), "GTiff")), 
                          raster(writeRaster(here("data", "intermediate", "ECOSTRESS", "ETinst_OGunits_Q3.tif"), "GTiff")), 
                          raster(writeRaster(here("data", "intermediate", "ECOSTRESS", "ETinst_OGunits_Q4.tif"), "GTiff"))))

writeRaster(ET_brick, here("data", "intermediate", "ECOSTRESS", "ETinst_OGunits.tif"), "GTiff", overwrite=TRUE)

################################################################################
################################################################################

# read in, change units, and resample all ET rasters
print("processing ET rasters")
ET_rasters <- lapply(dates, process)
# make a brick
ET_brick <- brick(ET_rasters)
#save as geotiff
dir.create(here("data", "intermediate", "ECOSTRESS"))
writeRaster(ET_brick, here("data", "intermediate", "ECOSTRESS", "ETinst_OGunits.tif"), "GTiff", overwrite=TRUE)

write.csv(as.character(as.Date(dates, "%Y%j%H%M%S")), here("data", "intermediate", "ECOSTRESS", "dates.csv"))

# read in, change units, and resample all Uncertainty rasters
print("processing Uncertainty rasters")
names(dates) <- str_replace(names(dates), 'ETinst', 'ETinstUncertainty') #the file names are the same except ETinst vs ETinstUncertainty
Uncertainty_rasters <- lapply(dates, process)
# make a brick
Uncertainty_brick <- brick(Uncertainty_rasters)
#save as geotiff
writeRaster(Uncertainty_brick, here("data", "intermediate", "PET", "ETUncertainty_OGunits.tif"), "GTiff", overwrite=TRUE)

