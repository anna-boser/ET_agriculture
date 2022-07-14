# This script builds the study area (ag and counterfactual) shapefiles. 
# In order to do this I use the 2018 DWR ag dataset as my extent of agriculture for both 2019 and 2020
# (I choose this because I find that the confusion between the CDL and DWR is fairly great and 
# the DWR includes fallow fields so it's unlikely to change dramatically from year to year).
# and then I establish the counterfactual by including any barren, grass/pasture, or shrubland 
# as identified by the 2019 and 2020 CDL within a 20 km radius of any agricultural land 
# (removing the ag land polygon plus a 70m buffer to ensure the 70m ECOSTRESS pixels don't get mixed)

# Anna Boser October 5, 2021

library(sf)
library(raster)
library(here)
library(tmap)
library(stringr)
library(dplyr)
library(stars)

# CDL: load and crop to California
# CDL2019 <- raster(here("data", "raw", "CDL", "CDL2019", "2019_30m_cdls.img")) 
# CDL2020 <- raster(here("data", "raw", "CDL", "CDL2020", "2020_30m_cdls.img")) 

# DWR
DWR <- read_sf(here("data", "raw", "DWR_crop", "i15_Crop_Mapping_2018.shp")) #%>%
#st_transform(st_crs(CDL2019))
DWR <- st_zm(DWR) # DWR in 3 dims with 0 for z value

DWR$CLASS2 %>% unique()

# see the Crop_Mapping_2018_metadata to see what the CLASS codes mean: 
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

# Ag polygon: same for 2019 and 2020
DWR_flat <- st_as_sf(st_union(DWR))
# rm(DWR)

# save ag polygon
dir.create(here("data", "intermediate", "study_area_shapefiles"))
dir.create(here("data", "intermediate", "study_area_shapefiles", "Agriculture"))
st_write(DWR_flat, here("data", "intermediate", "study_area_shapefiles", "Agriculture", "Agriculture.shp"))

# make a raster with 0 and 1 for where agriculture is present 
grid <- raster(here("data", "intermediate", "CA_grid.tiff"))

# CA counties for cropping
counties <- st_read(here("data", "raw", "shapefiles", "study_area_counties", "study_area_counties.shp")) %>%
  st_transform(st_crs(CDL2019))

CDL2019 <- CDL2019 %>% crop(counties)
# CDL2020 <- CDL2020 %>% crop(counties)

# get the code dictionary to keep only grassland/pasture, shrubland, and barren
code_dictionary <- read.csv(file = here("data",
                                        "intermediate",
                                        "CDL_code_dictionary.csv"))
counter_dic <- code_dictionary$counterfactual
names(counter_dic) <- code_dictionary$code

dir.create(here("data", "intermediate", "study_area_shapefiles", "Counterfactual"))

counterfactual <- function(year){
  CDL_counter <- crop(get(paste0("CDL", year)), buffer)
  CDL_counter <- mask(CDL_counter, buffer)
  values(CDL_counter) <- counter_dic[as.character(values(CDL_counter))]
  values(CDL_counter) <- ifelse(values(CDL_counter) == 1, 1, NA)
  
  counterfactual_sf <- st_as_sf(st_as_stars(CDL_counter), as_points = FALSE, merge = TRUE) %>% st_union() %>% st_as_sf()
  
  # save year counterfactual polygon
  dir.create(here("data", "intermediate", "study_area_shapefiles", "Counterfactual", year))
  st_write(DWR_flat, here("data", "intermediate", "study_area_shapefiles", "Counterfactual", year, paste0("counterfactual", year, ".shp")))
}

