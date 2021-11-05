# This script uses the CA storie index data obtained from 
# Campbell, Steve - FPAC-NRCS, Portland, OR <steve.campbell@usda.gov>
# and processes it to get a consistent 70m storie index raster over CA

# Anna Boser October 22 2021

library(here)
library(raster)
library(sf)
library(dplyr)
# library(tmap)

# my grid and map of california
CA_grid <- raster(here("data", "intermediate", "CA_grid.tif"))
CA <- st_read(here("data", "raw", "shapefiles", "california", "california.shp")) %>% st_transform(st_crs(CA_grid))

# the grid that the values in the CSV correspond to
gNATSGO_grid <- raster(here("data", "raw", "CA_storie", "CA_gNATSGO_MuRaster_tif", "MapunitRaster_10m.tif"))
gNATSGO_grid <- crop(gNATSGO_grid,  st_transform(CA, st_crs(gNATSGO_grid)))

# tm_shape(gNATSGO_grid) + tm_raster() + tm_shape(CA) + tm_borders()

# the storie index
storie <- read.csv(here("data", "raw", "CA_storie", "CA_all_NASIS_Storie_Index_SSURGO_STATSGO2.csv"))

# soil data are organized in a strange way where there are unique map units
# that are associated with a location (and thus can be mapped using the gNATSGO grid).
# However, there are often multiple components within one map unit but their location
# is unknown. Therefore, to get an average value of soil quality for each map key, 
# I need to average the storie index accross components, weighting each one by prevalence. 

storie <- storie %>% 
  group_by(mukey) %>%
  summarise(storie = stats::weighted.mean(Storie_Index_rev, comppct_r, na.rm = TRUE))

# create a storie index raster by joining through the mukey
gNATSGO_storie <- raster::subs(gNATSGO_grid, storie, by = "mukey")

#save 
dir.create(here("data", "intermediate", "CA_storie"))
writeRaster(gNATSGO_storie, here("data", "intermediate", "CA_storie", "gNATSGO_storie.tif"), overwrite = TRUE)

# resample the raster to the 70 CA_grid
CA_storie <- gNATSGO_storie %>% projectRaster(CA_grid) %>% resample(CA_grid, method = "bilinear")

writeRaster(CA_storie, here("data", "intermediate", "CA_storie", "CA_storie.tif"), overwrite = TRUE)

# check what it looks like
# tm_shape(CA_storie_storie) + tm_raster() + tm_shape(CA) + tm_borders()
# tmap_save(here("data", "intermediate", "CA_storie", "CA_storie_storie.html"))
