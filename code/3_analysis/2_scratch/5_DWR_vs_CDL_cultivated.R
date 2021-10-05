# This script checks the 2018 CDL and DWR datasets against each other for agreement. 
# see 4_study_ag&conterfactual for where I wrote the original code. 

# Anna Boser Oct 4 2021

library(sf)
library(raster)
library(here)
library(tmap)
library(stringr)
library(dplyr)

# CDL (2018)
CDL <- raster(here("data", "raw", "CDL", "CDL2018", "2018_30m_cdls.img"))

# DWR
DWR <- read_sf(here("data", "raw", "DWR_crop", "i15_Crop_Mapping_2018.shp")) %>%
  st_transform(crs(CDL))
DWR <- st_zm(DWR) # DWR in 3 dims with 0 for z value

# CA counties for cropping
counties <- st_read(here("data", "raw", "shapefiles", "study_area_counties", "study_area_counties.shp")) %>%
  st_transform(crs(CDL))

CA <- st_union(counties)

# crop the CDL to California
CDL <- crop(CDL, counties)

code_dictionary <- read.csv(file = here("data", 
                                        "intermediate", 
                                        "CDL_code_dictionary.csv"))

### create 0 and 1 raster for CDL

# make a dictionary for converting CDL numbers to cultivated and uncultivated. 
code_dictionary$cultivated <- ifelse(code_dictionary$cultivated == "Cultivated", 1, 0)
cultivate_dic <- code_dictionary$cultivated
names(cultivate_dic) <- code_dictionary$code

CDL_cultivated <- CDL
values(CDL_cultivated) <- cultivate_dic[as.character(values(CDL_cultivated))]


### create a 0 and 1 raster for DWR

DWR_cultivated <- rasterize(DWR, CDL, field = 1, fun = "max")
values(DWR_cultivated) <- ifelse(is.na(values(DWR_cultivated)), 0, 1)


### create the confusion matrix

DWR_CDL <- sum(values(DWR_cultivated)*values(CDL_cultivated))
notDWR_notCDL <- sum(ifelse(values(DWR_cultivated) == 0, 1, 0)*ifelse(values(CDL_cultivated) == 0, 1, 0))
DWR_notCDL <- sum(values(DWR_cultivated)*ifelse(values(CDL_cultivated) == 0, 1, 0))
notDWR_CDL <- sum(ifelse(values(DWR_cultivated) == 0, 1, 0)*values(CDL_cultivated))

confusion <- data.frame("DWR" = c(DWR_CDL, DWR_notCDL), "not_DWR" = c(notDWR_CDL, notDWR_notCDL), "rownames" = c("CDL", "not_CDL"), row.names = "rownames")

confusion$Sum <- apply(confusion, 1, sum)
confusion["Sum",] <- apply(confusion, 2, sum)


### save the confusion matrix

write.csv(confusion, here("scratch", "DWR_vs_CDL_cultivated_confusion.csv"))

