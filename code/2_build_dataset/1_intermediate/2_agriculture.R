# This script creates a shapefile and raster of agriculture based on DWR data

# Anna Boser November 5, 2021

library(sf)
library(raster)
library(here)
# library(tmap)
library(stringr)
library(dplyr)
library(fasterize)
# library(stars)

# DWR
DWR <- read_sf(here("data", "raw", "DWR_crop", "i15_Crop_Mapping_2019.shp")) #%>%
  #st_transform(st_crs(CDL2019))
DWR <- st_zm(DWR) # DWR in 3 dims with 0 for z value

DWR$CLASS2 %>% unique()

# see the Crop_Mapping_2018_metadata to see what the CLASS2 codes mean: 
# c("P" = "Pasture", 
#   "G" = "Grain and hay crops", 
#   "V" = "Vineyards", 
#   "U" = "Urban - residential, commercial, and industrial, unsegregated", 
#   "X" = "Unclassified fallow", 
#   "T" = "Truck, nursery, and berry crops",
#   "C" = "Citrus and subtropical", 
#   "D" = "Deciduous fruits and nuts",
#   "YP" = "Young Perennial", 
#   "F" = "Field crops", 
#   "R" = "Rice", 
#   "I"= "Idle")

s <- nrow(DWR)
# remove anything that's urban
DWR <- filter(DWR, CLASS2 != "U")
print(s - nrow(DWR)) #number of polygons that were urban

# Ag polygon: will use the same for all years
DWR <- st_make_valid(DWR)
DWR_flat <- st_as_sf(st_union(DWR))
# rm(DWR)

# save ag polygon
dir.create(here("data", "intermediate", "agriculture"))
dir.create(here("data", "intermediate", "agriculture", "ag_indicator_shapefile_dwr"))
st_write(DWR_flat, here("data", "intermediate", "agriculture", "ag_indicator_shapefile", "ag_indicator.shp"))

# make a raster with 0 and 1 for where agriculture is present 
CA_grid <- raster(here("data", "intermediate", "CA_grid.tif"))

DWR_flat <- DWR_flat %>% st_transform(st_crs(CA_grid))

st_write(DWR_flat, here("data", "intermediate", "agriculture", "ag_indicator_shapefile", "ag_indicator_new_crs.shp"))

DWR_raster <- fasterize(DWR_flat, CA_grid) # all pixels even partially covered by ag should be marked

# save raster
writeRaster(DWR_raster, here("data", "intermediate", "agriculture", "ag_indicator.tif"), "GTiff", overwrite=TRUE)
