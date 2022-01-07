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

m0 <- mean(PET[[c(1, 6)]])
writeRaster(m0, here("data", "intermediate", "PET", "PET_grouped_0.tif"), "GTiff", overwrite=TRUE)
rm(m0)

m1 <- PET[[7]]
writeRaster(m1, here("data", "intermediate", "PET", "PET_grouped_1.tif"), "GTiff", overwrite=TRUE)
rm(m1)

m2 <- mean(PET[[c(2, 8)]])
writeRaster(m2, here("data", "intermediate", "PET", "PET_grouped_2.tif"), "GTiff", overwrite=TRUE)
rm(m2)

m3 <- mean(PET[[c(3, 9)]])
writeRaster(m3, here("data", "intermediate", "PET", "PET_grouped_3.tif"), "GTiff", overwrite=TRUE)
rm(m3)

m4 <- mean(PET[[c(4, 10)]])
writeRaster(m4, here("data", "intermediate", "PET", "PET_grouped_4.tif"), "GTiff", overwrite=TRUE)
rm(m4)

m5 <- mean(PET[[c(5, 11)]])
writeRaster(m5, here("data", "intermediate", "PET", "PET_grouped_5.tif"), "GTiff", overwrite=TRUE)
rm(m5)

# m0 <- raster(here("data", "intermediate", "PET", "PET_grouped_0.tif"))
# m1 <- raster(here("data", "intermediate", "PET", "PET_grouped_1.tif"))
# m2 <- raster(here("data", "intermediate", "PET", "PET_grouped_2.tif"))
# m3 <- raster(here("data", "intermediate", "PET", "PET_grouped_3.tif"))
# m4 <- raster(here("data", "intermediate", "PET", "PET_grouped_4.tif"))
# m5 <- raster(here("data", "intermediate", "PET", "PET_grouped_5.tif"))

brick <- brick(list(m0,m1,m2,m3,m4,m5))
writeRaster(brick, here("data", "intermediate", "PET", "PET_grouped_brick.tif"), "GTiff", overwrite=TRUE)
mean <- mean(brick)
writeRaster(mean, here("data", "intermediate", "PET", "PET_grouped_average.tif"), "GTiff", overwrite=TRUE)

