# This script creates a measure of how "marshy" or "riparian" an area is 

# Anna Boser 2022

library(here)
library(raster)
library(dplyr)
library(sf)

# get the march rasters
water2019 <- raster(here("data", "raw", "JRC_water", "water2019.tif"))
water2020 <- raster(here("data", "raw", "JRC_water", "water2020.tif"))

# crop to CA
CA <- st_read(here("data", "raw", "shapefiles", "california", "california.shp"))
CA <- st_transform(CA, st_crs(water2019))

water2019 <- crop(water2019, extent(CA))
water2020 <- crop(water2020, extent(CA))

# mark missing values as no water and average
values(water2019) <- ifelse(values(water2019) == 0, 1, values(water2019))
values(water2020) <- ifelse(values(water2020) == 0, 1, values(water2020))
water <- mean(water2019, water2020)

# resample
CA_grid <- raster(here("data", "intermediate", "CA_grid.tif"))
water_grid <- water %>% projectRaster(CA_grid) %>% resample(CA_grid, method = "bilinear")

# blur and save
blur <- focal(water_grid, w=matrix(1, 21, 21))
writeRaster(blur, here("data", "intermediate", "water", "water21.tif"), "GTiff", overwrite=TRUE)

blur2 <- focal(blur, w=matrix(1, 51, 51))
writeRaster(blur2, here("data", "intermediate", "water", "water51.tif"), "GTiff", overwrite=TRUE)

blur3 <- focal(blur2, w=matrix(1, 101, 101))
writeRaster(blur3, here("data", "intermediate", "water", "water101.tif"), "GTiff", overwrite=TRUE)

blur4 <- focal(blur3, w=matrix(1, 201, 201))
writeRaster(blur4, here("data", "intermediate", "water", "water201.tif"), "GTiff", overwrite=TRUE)
