################################################################################
# This script downloads California's statewide crop mapping GIS from the 
# department of water resources (DWR)

# Anna Boser Sep 29 2021
################################################################################

library(here)

dir.create(here("data", "raw", "DWR_crop"))

download.file(url = "https://data.cnra.ca.gov/dataset/6c3d65e3-35bb-49e1-a51e-49d5a2cf09a9/resource/2dde4303-5c83-4980-a1af-4f321abefe95/download/i15_crop_mapping_2018_shp.zip", 
              destfile = here("data", "raw", "DWR_crop", "DWR_crop.zip"))

unzip(here("data", "raw", "DWR_crop", "DWR_crop.zip"), exdir = here("data", "raw", "DWR_crop"))
