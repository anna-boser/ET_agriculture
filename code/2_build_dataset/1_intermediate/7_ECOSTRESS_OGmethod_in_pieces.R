# This script resmaples and turns into one huge dataaset all the ET data. 
# This script writes the csv every once in a while so as not to run out of memory. 

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
names(timestamps) <- files #in order to find the files based on the timestamp

# get the list of timestamps we will consider
unique_timestamps <- unique(timestamps)
# remove those that don't have uncertainties
unique_timestamps <- unique_timestamps[unique_timestamps %in% timestamps[duplicated(timestamps)]]

# create a dataset for each timestamp
make_dataset <- function(timestamp){
  
  print(paste("New timestamp:", timestamp))
  
  timestamp_files <- names(timestamps[timestamps == timestamp])
  
  # read in rasters, resample to CA_grid, and turn into a rasterbrick
  read_and_rename <- function(file){
    raster <- raster(file)
    raster <- raster(file) %>% resample(CA_grid, method = "bilinear")
    return(raster)
  }
  ECO_brick <- brick(lapply(timestamp_files, read_and_rename))
  names(ECO_brick) <- ifelse(str_detect(names(ECO_brick), "ETinstUncertainty"), "ET_sd", "ET")
  
  # mask out non ag or natural
  mask(ECO_brick, pixels_of_interest)
  
  # convert rasters to dataframe rows
  dataset <- as.data.frame(ECO_brick, xy = TRUE, na.rm=TRUE)
  
  # add date labels
  dataset$date <- as.character(as.Date(timestamp, "%Y%j%H%M%S"))
  dataset$hhmmss <- substring(timestamp, 8)
  dataset$year <- year(as.Date(timestamp, "%Y%j%H%M%S"))
  
  #turn into data table for faster rbinding
  dataset <- as.data.table(dataset)
  
  return(dataset)
}

for (n in 1:length(unique_timestamps)){ 
  
  #announce which timestamp you're on
  print(paste("On timestamp" , n, "out of", length(unique_timestamps)))
  
  # get the timestamp
  ts <- unique_timestamps[n]
  
  # run the dataset command for all timestamps
  time <- Sys.time()
  dataset <- make_dataset(ts)
  print(paste("Time elapsed to build dataset:", Sys.time() - time))
  print(paste("Rows in dataset:", nrow(dataset)))
  
  # write the dataset
  csv_name <- here("data", "intermediate", "ECOSTRESS", "ECOSTRESS_chunked.csv")
  if (n == 1){ #start the file
    write.table(dataset, 
                file = csv_name, 
                sep = ",", 
                append = FALSE, 
                # quote = FALSE, 
                col.names = TRUE, 
                row.names = FALSE) 
  } else { #add to the file
    write.table(dataset, 
                file = csv_name, 
                sep = ",",
                append = TRUE, 
                # quote = FALSE,
                col.names = FALSE, 
                row.names = FALSE)
  }
  
  # clear to preserve memory
  rm(dataset)
}
