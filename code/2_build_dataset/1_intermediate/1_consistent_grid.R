# This script generates a 70m raster for all other data to be resampled to. 

#Anna Boser Oct 13 2021

library(here)
library(raster)
library(tmap)
library(dplyr)


raster <- raster(here("data", "raw", "ECOSTRESS", "ECO3ETPTJPL.001_EVAPOTRANSPIRATION_PT_JPL_ETinst_doy2019150001456_aid0001.tif"))
CA <- st_read(here("data", "raw", "shapefiles", "california", "california.shp")) %>% st_transform(st_crs(raster))
raster <- extend(raster, CA)

plot(raster)
tm_shape(CA) + tm_borders() + tm_shape(raster) + tm_raster()

values(raster) <- rep(NA, 244611913)
tm_shape(CA) + tm_borders() + tm_shape(raster) + tm_raster()

writeRaster(raster, here("data", "intermediate", "CA_grid.tif"), "GTiff", overwrite = TRUE)

