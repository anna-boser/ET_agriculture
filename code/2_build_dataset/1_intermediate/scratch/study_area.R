# Define a study area based on where ag and groundwater basins are

library(here)
library(sf)
library(raster)
library(dplyr)


# ag <- st_read(here("data", "raw", "DWR_crop", "i15_Crop_Mapping_2019.shp"))



# get rid of urban

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



# ag <- dplyr::filter(ag, CLASS2 != "U")
# fveg <- raster(here("data", "raw", "FVEG", "fveg_lifeform.tif"))
# 
# counties <- c("Tehama", "Glenn", "Butte", "Colusa", "Sutter", "Yuba", "Yolo", "Solano", "Sacramento", "San Joaquin", "Stanislaus", "Merced", "Madera", "Fresno", "Kings", "Tulare", "Kern")
# 
# # what does a 10km buffer look like? What about a 10km buffer but only with the acceptable vegetation types? 
# ag<- st_transform(ag, 3310)
# ag_flat <- st_as_sf(st_union(ag))
# ag_flattened <- st_zm(ag_flat, drop = TRUE, what = "ZM")
# 
# # save
# st_write(ag_flattened, here("scratch_data", "flat_ag_only.shp"))


ag_flattened <- st_read(here("scratch_data", "flat_ag_only.shp"))


ag_surround <- st_buffer(ag_flattened, 10000)



