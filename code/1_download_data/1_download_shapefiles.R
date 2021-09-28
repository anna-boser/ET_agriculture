################################################################################
# This script downloads US county shapefiles 
# and then breaks and zips them into separate files of a single county 
# in California's Central Valley
# to be used to make APPEEARS requests

# Anna Boser Sep 9 2021
################################################################################

library(here)
library(sf)
library(dplyr)

dir.create(here("data", "raw", "shapefiles"))
dir.create(here("data", "raw", "shapefiles", "counties_500k"))

download.file(url = "https://www2.census.gov/geo/tiger/GENZ2018/shp/cb_2018_us_county_500k.zip", 
              destfile = here("data", "raw", "shapefiles", "counties_500k", "counties_500k.zip"))

unzip(here("data", "raw", "shapefiles", "counties_500k", "counties_500k.zip"), exdir = here("data", "raw", "shapefiles", "counties_500k"))

#not sure if this deletes the zip file -- need to check.

US_counties <- st_read(here("data", "raw", "shapefiles", "counties_500k", "cb_2018_us_county_500k.shp"))

# If specific counties: 
# counties <- c("") # the counties that make up the study area

# If all counties: 
counties <- filter(US_counties, STATEFP == "06")$NAME # 06 is Califonia -- change if in different state

# create individual county shapefiles
dir.create(here("data", "raw", "shapefiles", "county_shapefiles"))

for (county in counties){
  county_shapefile <- filter(US_counties, NAME == county, STATEFP == "06") # 06 is Califonia -- change if in different state
  dir.create(here("data", "raw", "shapefiles", "county_shapefiles", county))
  st_write(county_shapefile, here("data", "raw", "shapefiles", "county_shapefiles", county, paste0(county, ".shp")))
  zip(here("data", "raw", "shapefiles", "county_shapefiles", county), 
      list.files(here("data", "raw", "shapefiles", "county_shapefiles", county), full.names = TRUE))
}

# create a single study area shapefile
county_shapefile <- filter(US_counties, STATEFP == "06")
dir.create(here("data", "raw", "shapefiles", "study_area_counties"))
st_write(county_shapefile, here("data", "raw", "shapefiles", "study_area_counties", "study_area_counties.shp"))
zip(here("data", "raw", "shapefiles", "study_area_counties"), 
    list.files(here("data", "raw", "shapefiles", "study_area_counties"), full.names = TRUE))

