# This script takes daily PET information, aggregates it to the time steps used in 
# this study, and resamples it to the consistent 70m grid. 

# Anna Boser October 22

library(here)
library(raster)
library(dplyr)
# library(tmap)
library(sf)
library(ncdf4) # package for netcdf manipulation
library(raster) # package for raster manipulation
library(rgdal) # package for geospatial analysis
library(ggplot2) # package for plotting

CA_grid <- raster(here("data", "intermediate", "CA_grid.tif"))
CA <- st_read(here("data", "raw", "shapefiles", "california", "california.shp")) %>% st_transform(st_crs(CA_grid))

PET2019 <- nc_open(here("data", "raw", "PET", "2019_daily_pet.nc"))
PET2020 <- nc_open(here("data", "raw", "PET", "2020_daily_pet.nc"))

lon <- ncvar_get(PET2019, "longitude")
lat <- ncvar_get(PET2019, "latitude")

# 2020 and 2019 have a different number of days (2020 is a leapyear)
time2019 <- ncvar_get(PET2019, "time")
time2020 <- ncvar_get(PET2020, "time")

# keep only California

# the smallest lon in the PET dataset's lon values that would encompass CA
minlon <- unique(lon)[lon < st_bbox(CA)$xmin]
lonstart <- length(minlon)
minlon <- minlon[length(minlon)]

# the largest lon in the PET dataset's lon values that would encompass CA
maxlon <- unique(lon)[lon > st_bbox(CA)$xmax]
maxlon <- maxlon[1]

# the smallest lat in the PET dataset's lat values that would encompass CA
minlat <- unique(lat)[lat < st_bbox(CA)$ymin]
minlat <- minlat[1]

# the largest lon in the PET dataset's lon values that would encompass CA
maxlat <- unique(lat)[lat > st_bbox(CA)$ymax]
latstart <- length(maxlat)
maxlat <- maxlat[length(maxlat)]

#how many to include
lonlen <- length(lon[lon > st_bbox(CA)$xmin & lon < st_bbox(CA)$xmax])
latlen <- length(lat[lat > st_bbox(CA)$ymin & lat < st_bbox(CA)$ymax])

# 2019
PET2019.array <- ncvar_get(PET2019, "pet", start = c(lonstart,latstart,1), count = c(lonlen,latlen,length(time2019)))
dim(PET2019.array)

#2020
PET2020.array <- ncvar_get(PET2020, "pet", start = c(lonstart,latstart,1), count = c(lonlen,latlen,length(time2020)))
dim(PET2020.array)

# turn into a rasterbrick
brick2019 <- brick(PET2019.array, crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
brick2020 <- brick(PET2020.array, crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))

# combine both
stack <- stack(brick2019, brick2020) #every layer is one day starting January 1 2019

brick <- t(brick(stack))
dim(brick)
extent(brick)<-extent(c(minlon, maxlon, minlat, maxlat))
values(brick)[values(brick) > 600000000000000000000000000000000000] <- NA # get rid of the ocean with super high PET

plot(brick, 'layer.700')

#save as geotiff
dir.create(here("data", "intermediate", "PET"))
writeRaster(brick, here("data", "intermediate", "PET", "PETbrick_OGres.tif"), "GTiff", overwrite=TRUE)

# # resample to 70m
# CA_grid_731_bands <- brick(stack(replicate(731, CA_grid)))
# brick <- resample(brick, CA_grid_731_bands, method = "bilinear") 
# 
# # save as a geotiff 
# writeRaster(brick, here("data", "intermediate", "PET", "PETbrick.tif"), "GTiff", overwrite=TRUE)
# 
