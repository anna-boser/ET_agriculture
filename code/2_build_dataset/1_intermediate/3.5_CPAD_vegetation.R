# This script creates a flattened shapefile of and standardized grid of all 
# protected lands in California. 
# It also saves a raster that is only protected areas without forest and with 
# natural vegetation according to (1) the CDL and (2) the CDL and FVEG
# dataset available: https://data.cnra.ca.gov/dataset/california-protected-areas-database

library(sf)
library(here)
library(dplyr)
library(fasterize)

# read in the shapefile of the holdings, or the smallest unit
CPAD <- st_read(here("data/raw/CPAD/CPAD_2022a/CPAD_2022a_Holdings.shp"))

# remove any holdings in GAP 4, since these are the areas that are not protected from changes. 
# see https://www.usgs.gov/core-science-systems/science-analytics-and-synthesis/gap/science/pad-us-data-overview?qt-science_center_objects=0#qt-science_center_objects for more info. 
CPAD123 <- filter(CPAD, (CPAD$GAP4_acres/CPAD$ACRES)<=0)
print(nrow(CPAD123)/nrow(CPAD))

# flatten the shapefile
CPAD123 <- st_as_sf(st_union(CPAD123))

# save ag polygon
dir.create(here("data", "intermediate", "potected_areas"))
dir.create(here("data", "intermediate", "potected_areas", "CPAD123_indicator_shapefile"))
st_write(CPAD123, here("data", "intermediate", "potected_areas", "CPAD123_indicator_shapefile", "CPAD123_indicator.shp"))

# get grid 
CA_grid <- raster(here("data", "intermediate", "CA_grid.tif")) # consistent grid
CPAD123 <- CPAD123 %>% st_transform(st_crs(CA_grid)) # change projection to the grid projection

# save new shapefile
st_write(CPAD123, here("data", "intermediate", "potected_areas", "CPAD123_indicator_shapefile", "CPAD123_indicator_new_crs.shp"))

# turn the shapefile into a binary mask
CPAD123_raster <- fasterize(CPAD123, CA_grid) # all pixels even partially covered are marked

# save raster
writeRaster(CPAD123_raster, here("data", "intermediate", "potected_areas", "CPAD123_indicator.tif"), "GTiff", overwrite=TRUE)

# Read in vegetation masks
CDL_counterfactual <- raster(here("data", "intermediate", "counterf", "counterf_indicator.tif"))

# compare the number of pixels here to the number of pixels in all nonforest vegetation. 

# remove all forest vegetation

# save new rasters



