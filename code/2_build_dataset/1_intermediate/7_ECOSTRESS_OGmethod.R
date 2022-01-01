# This script resmaples and turns into one huge dataaset all the ET data. 
# Note that this script does not write in chunks so we might run out of space. 

# Anna Boser Jan 1, 2022

library(here)
library(raster)
library(data.table)
library(dplyr)
library(ggplot2)
library(stringr)

# get the ET file names
files <- list.files(path = here("data", "raw", "ECOSTRESS"), full.names = TRUE)

# empty consistent grid
CA_grid <- raster(here("data", "intermediate", "CA_grid.tif"))

# ag and natural land rasters
ag <- raster(here("data", "intermediate", "agriculture", "ag_indicator.tif"))
natural <- raster(here("data", "intermediate", "counterf", "counterf_indicator.tif"))
pixels_of_interest <- ag|natural

# get the different image timestamps
timestamps <- str_extract(files, regex('(?<=_doy)[0-9]*(?=_aid0001.tif)'))
unique_timestamps <- unique(timestamps)
names(timestamps) <- files

# create a dataset for each timestamp
make_dataset <- function(timestamp){
  
  print(paste("New timestamp:", timestamp))
  
  timestamp_files <- names(timestamps[timestamps == timestamp])
  
  # read in rasters, resample to CA_grid, and turn into a rasterbrick
  read_and_rename <- function(file){
    raster <- raster(file)
    names(raster) <- str_extract(names(raster), regex('(?<=_PT_JPL_)[A-z_]*(?=_doy)'))
    raster <- raster(file) %>% resample(CA_grid, method = "bilinear")
    return(raster)
  }
  ECO_brick <- brick(lapply(timestamp_files, read_and_rename))
  
  rename_cols <- function(name){
    if (str_detect(name, "ETinstUncertainty")){
      newname <- "ET_sd"
    } else {
      newname <- "ET"
    }
    return(newname)
  }
  
  ncol <- length(names(ECO_brick))
  names(ECO_brick) <- sapply(names(ECO_brick), rename_cols)
  
  # mask out non ag or natural
  mask(ECO_brick, pixels_of_interest)
  
  # convert rasters to dataframe rows
  dataset <- as.data.frame(ECO_brick, xy = TRUE, na.rm=TRUE)
  
  # if the ET_sd column is missing, add it with a bunch of NA values
  if (is.null(dataset$ET_sd)){
    dataset$ET_sd <- NA
  }
  
  # add date labels
  dataset$date <- as.character(as.Date(timestamp, "%Y%j%H%M%S"))
  dataset$hhmmss <- substring(timestamp, 8)
  dataset$year <- year(as.Date(timestamp, "%Y%j%H%M%S"))
  
  #turn into data table for faster rbinding
  dataset <- as.data.table(dataset)
  
  return(dataset)
}

# run the dataset command for all timestamps
time <- Sys.time()
dataset_list <- lapply(unique_timestamps, make_dataset)
dataset <- rbindlist(dataset_list, fill = TRUE)
print(paste("Time elapsed to build dataset:", Sys.time() - time))

# write the dataset
write.csv(dataset, file = here("data", "intermediate", "ECOSTRESS.csv"), row.names = FALSE)