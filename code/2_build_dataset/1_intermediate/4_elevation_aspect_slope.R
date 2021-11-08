# This script uses the DEM elevations data to create rasters for elevation, aspect and slope

# Anna Boser Oct 22 2021

library(here)
library(raster)
library(dplyr)
# library(tmap)
library(sf)

CA_grid <- raster(here("data", "intermediate", "CA_grid.tif"))
CA <- st_read(here("data", "raw", "shapefiles", "california", "california.shp")) %>% st_transform(st_crs(CA_grid))

file <- here("data", "raw", "DEM", "dem90_hf.tif")
elevation <- raster(file) %>% projectRaster(CA_grid) %>% resample(CA_grid, method = "bilinear")
print(elevation)

dir.create(here("data", "intermediate", "topography"))

# tm_shape(elevation) + tm_raster() + tm_shape(CA) + tm_borders()
# tmap_save(here("data", "intermediate", "NED", "elevation.html"))
writeRaster(elevation, here("data", "intermediate", "topography", "elevation.tif"), overwrite = TRUE)

# make slope and aspect layers
slope <- raster::terrain(elevation, opt = "slope")
# tm_shape(CA) + tm_borders() + tm_shape(slope) + tm_raster()
# tmap_save(here("data", "intermediate", "NED", "slope.html"))
writeRaster(slope, here("data", "intermediate", "topography", "slope.tif"), overwrite = TRUE)

aspect <- raster::terrain(elevation, opt = "aspect")
# tm_shape(CA) + tm_borders() + tm_shape(aspect) + tm_raster()
# tmap_save(here("data", "intermediate", "NED", "aspect.html"))
writeRaster(aspect, here("data", "intermediate", "topography", "aspect.tif"), overwrite = TRUE)

