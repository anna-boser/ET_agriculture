# This script creates a shapefile and raster of the natural vegetation counterfacutal
# While I did look into fveg, it didn't seem like it was necessarily 
# better quality, higher resolution, or more recent than the CDL data. 
# Therefore, I specifically use CDL data and include anything that is not included in the 
# DWR agriculture dataset and is marked as barren, shrubland, or grassland/pasture. 
# This should in theory get rid of any pasture in the CDL dataset since it is marked 
# in the DWR data. 

# Anna Boser Nov 8, 2021

library(sf)
library(raster)
library(here)
# library(tmap)
library(stringr)
library(dplyr)

# fveg <- raster(here("data", "raw", "FVEG", "fveg_tif", "fveg15_1.tif.ovr"))
# fveg_key <- st_read(here("data", "raw", "FVEG", "fveg_tif", "fveg15_1.tif.vat.dbf"))

# consistent grid
CA_grid <- raster(here("data", "intermediate", "CA_grid.tif"))

# The CDL. I don't need to bother with both 2019 and 2020 because they don't change
# since the non ag land cover data is actually from the NLCD. 

CDL <- raster(here("data", "raw", "CDL", "CDL2020", "2020_30m_cdls.img"))
CA <- st_read(here("data", "raw", "shapefiles", "california", "california.shp")) %>% st_transform(st_crs(CDL))
CDL <- crop(CDL, CA)

code_dictionary <- read.csv(file = here("data", 
                                        "intermediate", 
                                        "CDL_code_dictionary.csv"))

# make a dictionary for converting CDL numbers to counterfactual and not
counterfactual_dic <- code_dictionary$counterfactual
names(counterfactual_dic) <- code_dictionary$code

# converting CDL numbers to counterfactual (1) and not (0)
CDL_counterfactual <- CDL
values(CDL_counterfactual) <- counterfactual_dic[as.character(values(CDL_counterfactual))]

# resample to the CA_grid
CDL_counterfactual <- CDL_counterfactual %>% projectRaster(CA_grid) %>% resample(CA_grid, method = "bilinear")
# get rid of non-pure counterfactual pixels
values(CDL_counterfactual) <- ifelse(values(CDL_counterfactual) == 1, 1, NA)

# the DWR ag indicator raster
DWR <- raster(here("data", "intermediate", "agriculture", "ag_indicator.tif"))
# get rid of ag pixels
values(CDL_counterfactual) <- ifelse(values(DWR) == 1, NA, values(CDL_counterfactual))

# save the raster 
dir.create(here("data", "intermediate", "counterf"))
writeRaster(CDL_counterfactual, here("data", "intermediate", "counterf", "counterf_indicator.tif"), "GTiff", overwrite=TRUE)
