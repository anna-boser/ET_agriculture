# This script takes daily PET information, aggregates it to the time steps used in 
# this study, and resamples it to the consistent 70m grid. 

# Anna Boser October 22

library(here)
library(raster)
library(dplyr)
library(tmap)
library(sf)
library(ncdf4) # package for netcdf manipulation
library(raster) # package for raster manipulation
library(rgdal) # package for geospatial analysis
library(ggplot2) # package for plotting

CA_grid <- raster(here("data", "intermediate", "CA_grid.tif"))
CA <- st_read(here("data", "raw", "shapefiles", "california", "california.shp")) %>% st_transform(st_crs(CA_grid))

PET2019 <- nc_open(here("data", "raw", "PET", "2019_daily_pet.nc"))

longitude <- ncvar_get(PET2019, "longitude")
latitude <- ncvar_get(PET2019, "latitude", verbose = F)
time <- ncvar_get(PET2019, "time")

PET2019.array <- ncvar_get(PET2019, "pet")
