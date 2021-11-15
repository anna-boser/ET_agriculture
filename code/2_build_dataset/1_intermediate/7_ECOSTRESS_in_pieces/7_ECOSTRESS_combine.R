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


# read them all in and stack them together
ET_bricks <- list()
for (i in 1:19){
  ET_bricks[i] <- brick(here("data", "intermediate", "ECOSTRESS", paste0("ETinst_OGunits_", i, ".tif")))
}

ET_brick <- brick(ET_bricks)
writeRaster(ET_brick, here("data", "intermediate", "ECOSTRESS", "ETinst_OGunits.tif"), "GTiff", overwrite=TRUE)
