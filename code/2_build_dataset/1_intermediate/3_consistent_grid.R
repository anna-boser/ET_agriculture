# This script chooses one random 70m grid from the ECOSTRESS data and saves it as the grid to resample all data to and build datasets from. 

#Anna Boser Oct 13 2021

library(here)
library(raster)
# library(tmap)
  
file <- list.files(here("data", "raw", "ECOSTRESS"))[1] # pick the first file in the ECOSTRESS data
raster <- raster(here("data", "raw", "ECOSTRESS", file))

CA <- st_read(here("data", "raw", "shapefiles", "california", "california.shp")) %>% st_transform(st_crs(raster))

# tm_shape(CA) + tm_borders() + tm_shape(raster) + tm_raster()
