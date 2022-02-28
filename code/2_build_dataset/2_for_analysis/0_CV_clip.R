# This script takes the full CA datasets and clips and masks them to just the central valley 

library(raster)
library(dplyr)
library(here)
library(sf)
library(stringr)

# central valley shapefile
cv <- st_read(here("data/raw/shapefiles/cimis_CV/cimis_CV.shp"))

# at to get correct crs
ag <- raster(here("data/intermediate/agriculture/ag_indicator.tif"))

# transform cv
cv <- st_transform(cv, st_crs(ag))
dir.create(here("data/intermediate/cv"))
st_write(cv, here("data/intermediate/cv/cv.shp"))

# make a list of every raster
strings <- c("data/intermediate/agriculture/ag_indicator.tif", 
             "data/intermediate/counterf/counterf_indicator.tif", 
             "data/intermediate/topography/elevation.tif", 
             "data/intermediate/topography/aspect.tif", 
             "data/intermediate/topography/slope.tif",
             "data/intermediate/CA_storie/CA_storie.tif", 
             "data/intermediate/PET/PET_grouped_0.tif", 
             "data/intermediate/PET/PET_grouped_1.tif", 
             "data/intermediate/PET/PET_grouped_2.tif", 
             "data/intermediate/PET/PET_grouped_3.tif", 
             "data/intermediate/PET/PET_grouped_4.tif", 
             "data/intermediate/PET/PET_grouped_5.tif",
             "data/intermediate/CA_grid.tif")

crop_mask <- function(string){
  old <- raster(here(string))
  new <- mask(old, cv) %>% crop(cv)
  newstring <- str_split(string, "[.]")
  newstring <- paste0(newstring[[1]][1], "_cv.", newstring[[1]][2])
  writeRaster(new, here(newstring), overwrite=TRUE)
}

lapply(strings, crop_mask)
