# average the output of 6.5_PET_yeargrouped.py across years such that you end up with a stack of only 6 images
# Anna Boser Jan 5, 2022

library(here)
library(raster)
library(dplyr)
library(rgdal)
library(data.table)
library(stringr)
library(lubridate)
library(sf)

PET <- brick(here("data", "intermediate", "PET", "PET_yeargrouped_avg.tif"))

# group it by month group and avg

m <- mean(PET[[c(1, 6)]])
writeRaster(m, here("data", "intermediate", "PET", "PET_grouped_0.tif"), "GTiff", overwrite=TRUE)
rm(m)

m <- PET[[7]]
writeRaster(m, here("data", "intermediate", "PET", "PET_grouped_1.tif"), "GTiff", overwrite=TRUE)
rm(m)

m <- mean(PET[[c(2, 8)]])
writeRaster(m, here("data", "intermediate", "PET", "PET_grouped_2.tif"), "GTiff", overwrite=TRUE)
rm(m)

m <- mean(PET[[c(3, 9)]])
writeRaster(m, here("data", "intermediate", "PET", "PET_grouped_3.tif"), "GTiff", overwrite=TRUE)
rm(m)

m <- mean(PET[[c(4, 10)]])
writeRaster(m, here("data", "intermediate", "PET", "PET_grouped_4.tif"), "GTiff", overwrite=TRUE)
rm(m)

m <- mean(PET[[c(5, 11)]])
writeRaster(m, here("data", "intermediate", "PET", "PET_grouped_5.tif"), "GTiff", overwrite=TRUE)
rm(m)

