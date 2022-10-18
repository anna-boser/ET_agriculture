# This script takes the vegetation dataset from 3_vegetation and checks it with the
# FVEG dataset to ensure that all vegetation pixels truly are vegetation. 

# Anna Boser
# Sep 27, 2022


library(here)
library(raster)
library(dplyr)

fveg <- raster(here("data", "raw", "FVEG", "fveg_lifeform.tif"))

# key = c(1 = "CONIFER", 
#         2 = "SHRUB", 
#         3 = "HERBACEOUS", 
#         4 = "BARREN/OTHER", 
#         5 = "URBAN", 
#         6 = "HARDWOOD", 
#         7 = "WATER", 
#         8 = "AGRICULTURE")

# I'm interested in 2, 3, and 4

# for testing
# fveg = crop(fveg, extent(-636270 + 500000, 552420 - 500000, -612510 + 500000, 530310 - 500000)) 
# plot(fveg)

values(fveg) <- ifelse(values(fveg) %in% c(2,3,4), 1, 0)

# resample to the 70m grid
CA_grid <- raster(here("data", "intermediate", "CA_grid.tif"))
fveg <- fveg %>% projectRaster(CA_grid) %>% resample(CA_grid, method = "bilinear")

# remove unpure pixels
values(fveg) <- ifelse(values(fveg) ==1, 1, NA)

# get rid of ag pixels
DWR <- raster(here("data", "intermediate", "agriculture", "ag_indicator.tif"))
# DWR <- raster(here("data", "intermediate", "agriculture", "2018", "ag_indicator.tif"))
values(fveg) <- ifelse(!is.na(values(DWR)), NA, values(fveg))

# save it 
writeRaster(fveg, here("data", "intermediate", "counterf", "fveg_indicator.tif"), "GTiff", overwrite=TRUE)

