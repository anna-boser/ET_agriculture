### this script takes information from the USGS and the DWR crop data 
### to make a dataset with county level information on irrigation and crop cover

# Anna Boser
# May 5, 2022

library(here)
library(stringr)
library(sf)
library(tmap)
library(data.table)
library(tidyr)
library(dplyr)
library(ggplot2)

####################################
# county shapefiles
####################################

counties <- st_read(here("data", "raw", "shapefiles", "study_area_counties", "study_area_counties.shp"))

####################################
# DWR crop data
####################################

DWR <- read_sf(here("data", "raw", "DWR_crop", "i15_Crop_Mapping_2018.shp")) 
DWR <- st_zm(DWR) # DWR in 3 dims with 0 for z value
DWR <- filter(DWR, CLASS2 != "U") # remove Urban

# for each county, get the area of farmland in m^2
flatten <- function(s){
  d <- filter(DWR, CLASS2 == s) %>% st_make_valid()
  d <- st_union(d) %>% st_as_sf() %>% st_make_valid()
  d$CLASS2 = s
  return(d)
}

ss <- unique(DWR$CLASS2)

DWR_flat <- lapply(ss, flatten)
DWR_flat <- do.call(rbind, DWR_flat)

st_write(DWR_flat, here("data", "intermediate", "agriculture", "ag_classes.shp")) # save this

ag_by_county <- as_tibble(st_intersection(DWR_flat, counties))
ag_by_county$area <- st_area(ag_by_county$x)
ag_by_county$x <- NULL

ag_area_by_county <- ag_by_county %>% 
  group_by(NAME) %>%
  summarise(total_ag_m2 = sum(area))

counties <- base::merge(counties, ag_area_by_county, by = "NAME", all.x = TRUE)
counties$total_ag_m2 <- ifelse(is.na(counties$total_ag_m2), ag_by_county$area[1]*0, counties$total_ag_m2)

# for each county, get the area of each crop type
crop_area_by_county <- ag_by_county %>%
  select("NAME", "area", "CLASS2") %>% 
  pivot_wider(names_from = "CLASS2", values_from = "area", names_prefix = "m2_", values_fill = ag_by_county$area[1]*0)

counties <- base::merge(counties, crop_area_by_county, by = "NAME", all.x = TRUE)

# for each county, get the percent of each crop type
ag_by_county <- merge(ag_by_county, ag_area_by_county, by = "NAME")
ag_by_county$frac = ag_by_county$area/ag_by_county$total_ag_m2

crop_frac_by_county <- ag_by_county %>%
  select("NAME", "frac", "CLASS2") %>% 
  pivot_wider(names_from = "CLASS2", values_from = "frac", names_prefix = "frac_", values_fill = ag_by_county$area[1]*0/ag_by_county$area[1]*0)

counties <- base::merge(counties, crop_frac_by_county, by = "NAME", all.x = TRUE)

# for each county, get the area of farmland within the CV study area

CV <- st_read(here("data", "raw", "shapefiles", "cimis_CV", "cimis_CV.shp")) %>% st_transform(st_crs(DWR))# central valley shapefile
DWR_CV <- st_intersection(DWR_flat, CV)

ag_by_county_CV <- as_tibble(st_intersection(DWR_CV, counties))
ag_by_county_CV$area <- st_area(ag_by_county_CV$x)
ag_by_county_CV$x <- NULL

ag_area_by_county_CV <- ag_by_county_CV %>% 
  group_by(NAME) %>%
  summarise(total_ag_m2_CV = sum(area))

counties <- base::merge(counties, ag_area_by_county_CV, by = "NAME", all.x = TRUE)
counties$total_ag_m2_CV <- ifelse(is.na(counties$total_ag_m2_CV), ag_by_county_CV$area[1]*0, counties$total_ag_m2_CV)

# get the fraction of farmland that's in the study area
counties$ag_CV_frac <- counties$total_ag_m2_CV/counties$total_ag_m2

# get crop cover within the CV
crop_area_by_county_CV <- ag_by_county_CV %>%
  select("NAME", "area", "CLASS2") %>% 
  pivot_wider(names_from = "CLASS2", values_from = "area", names_prefix = "m2_CV", values_fill = ag_by_county$area[1]*0)

counties <- base::merge(counties, crop_area_by_county_CV, by = "NAME", all.x = TRUE)

# save this file
dir.create(here("data", "intermediate", "counties"))
st_write(counties, here("data", "intermediate", "counties", "counties_ag_stats.shp")) # save this


####################################
# USGS Irrigation Data
####################################
irrigation2015 <- read.csv(here("data", #this is data from 2015 (most recent)
                                "raw", 
                                "USGS_waterdata",
                                "2015",
                                "water_use"), sep = "\t")[-1,] #first row just tells you the size of the entries; remove

irrigation2010 <- read.csv(here("data", #this is data from 2010
                                "raw", 
                                "USGS_waterdata",
                                "2010",
                                "water_use"), sep = "\t")[-1,] #first row just tells you the size of the entries; remove

irrigation2015$year <- 2015
irrigation2010$year <- 2010

irrigation <- rbind(irrigation2015, irrigation2010)

rm(irrigation2010)
rm(irrigation2015)

# remove the "County" suffix to each county name in order to match to county shapefile names
irrigation$NAME <- str_remove(irrigation$county_nm, " County") 

# convert billions of gallons per day to kg per day
conversion <- function(Mgal.d){
  Mgal.d = as.numeric(Mgal.d)
  kg.d = Mgal.d * 3.785411784 * 1000000
}

to_convert = names(irrigation)[c(6:10, 15)] #the names of the columns that are in Mgal/d and need to be converted
irrigation <- mutate(irrigation, across(to_convert, conversion))


# convert thousands of acres to square meters
conversion <- function(tacre){
  tacre = as.numeric(tacre)
  m2 = tacre * 1000 * 4046.86 # conversion to acres and conversion to square meters
}

to_convert = names(irrigation)[c(11:14)] #the names of the columns that are in thousand of acres and need to be converted

irrigation <- mutate(irrigation, across(to_convert, conversion))

# add a mm/day and mm/year variable
# keep in mind the column names no longer reflect the true units
irrigation$mm.day <- irrigation$Irrigation..Crop.total.self.supplied.withdrawals.for.crops..fresh..in.Mgal.d/irrigation$Irrigation..Crop.total.irrigation.for.crops..in.thousand.acres

irrigation$mm.year <- irrigation$mm.day*365

# add columns for fraction covered by different irrigation technologies
irrigation <- irrigation %>% 
  mutate(
    sprinkler = Irrigation..Crop.sprinkler.irrigation.for.crops..in.thousand.acres/Irrigation..Crop.total.irrigation.for.crops..in.thousand.acres, 
    microirrigation = Irrigation..Crop.microirrigation.for.crops..in.thousand.acres/Irrigation..Crop.total.irrigation.for.crops..in.thousand.acres, 
    surface = Irrigation..Crop.surface.irrigation.for.crops..in.thousand.acres/Irrigation..Crop.total.irrigation.for.crops..in.thousand.acres)


counties_irrigation <- base::merge(counties, irrigation, by = "NAME")

# save

st_write(counties_irrigation, here("data", "intermediate", "counties", "counties_ag_and_water.shp"))
