# This script uses the NED elevations data to create rasters for elevation, aspect and slope

# Anna Boser Oct 22 2021

library(here)
library(raster)
library(dplyr)
library(tmap)
library(sf)

CA_grid <- raster(here("data", "intermediate", "CA_grid.tif"))
CA <- st_read(here("data", "raw", "shapefiles", "california", "california.shp")) %>% st_transform(st_crs(CA_grid))

files <- list.files(here("data", "raw", "NED", "elevation_NED30M_ca_3948100_01"), pattern = ".tif", full.names = TRUE)
notfiles <-  list.files(here("data", "raw", "NED", "elevation_NED30M_ca_3948100_01"), pattern = ".tif.", full.names = TRUE)

files <- files[!(files %in% notfiles)]
rm(notfiles)
# there are 69 files that cover california at 30m resolution

# make a single big California raster on the CA grid
elevation <- raster(files[1]) %>% projectRaster(CA_grid) %>% resample(CA_grid, method = "bilinear")
for (file in files){
  raster <- raster(file) %>% projectRaster(CA_grid) %>% resample(CA_grid, method = "bilinear")
  print(raster)
  elevation <- mosaic(elevation, raster, tolerance = 30, fun = mean)
}

dir.create(here("data", "intermediate", "NED"))

tm_shape(elevation) + tm_raster() + tm_shape(CA) + tm_borders()
tmap_save(here("data", "intermediate", "NED", "elevation.html"))
writeRaster(elevation, here("data", "intermediate", "NED", "elevation.tif"), overwrite = TRUE)

# make slope and aspect layers
slope <- raster::terrain(elevation, opt = "slope")
tm_shape(CA) + tm_borders() + tm_shape(slope) + tm_raster()
tmap_save(here("data", "intermediate", "NED", "slope.html"))
writeRaster(slope, here("data", "intermediate", "NED", "slope.tif"), overwrite = TRUE)

aspect <- raster::terrain(elevation, opt = "aspect")
tm_shape(CA) + tm_borders() + tm_shape(aspect) + tm_raster()
tmap_save(here("data", "intermediate", "NED", "aspect.html"))
writeRaster(aspect, here("data", "intermediate", "NED", "aspect.tif"), overwrite = TRUE)

