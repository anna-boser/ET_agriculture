# This script generates a dataframe identifiying pixels fully covered by a single crop

# Anna Boser, Mar 4, 2021

library(raster)
library(data.table)
library(dplyr)
library(exactextractr)
library(tidyverse)
library(sf)
library(here)
library(sf)
library(Rcpp)


# Create raster
grid <- raster(here("data", "intermediate", "CA_grid_cv.tif"))

# polygon: crops
polygons <- read_sf(here("data", "raw", "DWR_crop", "i15_Crop_Mapping_2018.shp")) #%>%
polygons <- st_zm(polygons) # DWR in 3 dims with 0 for z value

# Match raster and polygon crs 
polygons_reproj <- polygons %>% 
  st_transform(st_crs(grid))

geoweights <- rbindlist(exactextractr::exact_extract(grid, polygons_reproj, progress = T, include_cell = T, include_cols = c("CLASS2"), include_xy = T))

# only keep pixels that are 50% or more a certain county 
crop_pixels <- geoweights[coverage_fraction==1]
crop_pixels$coverage_fraction <- NULL

# check that this removed duplicate pixels
length(unique(crop_pixels$cell)) == length(crop_pixels$cell)

# remove NA value column
crop_pixels$value = NULL

# add in the full name of the crop type
cropnames <- c("P" = "Pasture",
  "G" = "Grain and hay crops",
  "V" = "Vineyards",
  "U" = "Urban - residential, commercial, and industrial, unsegregated",
  "X" = "Unclassified fallow",
  "T" = "Truck, nursery, and berry crops",
  "C" = "Citrus and subtropical",
  "D" = "Deciduous fruits and nuts",
  "YP" = "Young Perennial",
  "F" = "Field crops",
  "R" = "Rice",
  "I"= "Idle")

crop_pixels$cropnames <- cropnames[crop_pixels$CLASS2]

## Save outputs 
## -----------------------------------------------

dir.create(here::here("data", "intermediate", "crops"), recursive=T)

# Save geoweights 
fwrite(crop_pixels, file = file.path(here("data", "intermediate", "crops", "crops.csv")))

# save the partial fractions too in case I want those for some reason later
fwrite(geoweights, file = file.path(here("data", "intermediate", "crops", "crops_partial.csv")))

