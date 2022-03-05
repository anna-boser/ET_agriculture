# This script takes the counties shapefile and the central valley raster
# and outputs a data table with the county for each pixel

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

# polygon: counties
polygons <- st_read(here("data", "raw", "shapefiles", "counties_500k", "cb_2018_us_county_500k.shp"))
polygons <- dplyr::filter(polygons, STATEFP == "06")

# Match raster and polygon crs 
polygons_reproj <- polygons %>% 
  st_transform(st_crs(grid))

geoweights <- rbindlist(exactextractr::exact_extract(grid, polygons_reproj, progress = T, include_cell = T, include_cols = c("NAME"), include_xy = T))

# only keep pixels that are 50% or more a certain county 
county_pixels <- geoweights[coverage_fraction>=.5]

# check that this removed duplicate pixels
length(unique(county_pixels$cell)) == length(county_pixels$cell)

# remove NA value column
county_pixels$value = NULL

## Save outputs 
## -----------------------------------------------

dir.create(here::here("data", "intermediate", "counties"), recursive=T)

# Save geoweights 
fwrite(county_pixels, file = file.path(here("data", "intermediate", "counties", "counties.csv")))

  