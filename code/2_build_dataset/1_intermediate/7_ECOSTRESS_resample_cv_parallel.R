# This file takes the ECOSTRESS data and resamples it to the consistent CA grid. 
# It also creates an accompanying brick of uncertainties. 
# If the uncertainties are missing, that ET tif is discarded. 

# Anna Boser November 5, 2021

library(here)
library(raster)
library(dplyr)
library(rgdal)
library(data.table)
library(stringr)
library(lubridate)
library(sf)
library(parallel)

CA_grid <- raster(here("data", "intermediate", "CA_grid_cv.tif"))
CA <- st_read(here("data", "raw", "shapefiles", "cimis_CV", "cimis_CV.shp")) %>% st_transform(st_crs(CA_grid))

# get the ET file names
files <- list.files(here::here("data", 
                               "raw", 
                               "ECOSTRESS_cv"), 
                    full.names = TRUE) %>% unique() #get rid of any duplicates

# get the different image timestamps
timestamps <- str_extract(files, regex('(?<=_doy)[0-9]*(?=_aid0001.tif)'))
names(timestamps) <- files #in order to find the files based on the timestamp

# get the list of timestamps we will consider
unique_timestamps <- unique(timestamps)
# remove those that don't have uncertainties
unique_timestamps <- unique_timestamps[unique_timestamps %in% timestamps[duplicated(timestamps)]]

length(unique_timestamps)

# define read and resample function
read_resample <- function(file){
  raster <- raster(file)
  raster <- raster(file) %>% resample(CA_grid, method = "bilinear")
  return(raster)
}

# define function that saves the tifs for the files with a certain timestamp
process <- function(timestamp){
  time <- Sys.time()
  print(paste("New timestamp:", timestamp))
  
  timestamp_files <- names(timestamps[timestamps == timestamp])
  
  # get the ET and the sd
  ET_file <- str_subset(timestamp_files, regex('(?<=PT_JPL_)ETinst(?=_doy)'))
  sd_file <- str_subset(timestamp_files, regex('(?<=PT_JPL_)ETinstUncertainty(?=_doy)'))
  T_file <- str_subset(timestamp_files, regex('(?<=PT_JPL_)ETcanopy(?=_doy)'))
  PET_file <- str_subset(timestamp_files, regex('(?<=PT_JPL_)PET(?=_doy)'))
  
  # ascertain that the timestamp has both ET and ETsd
  if (length(ET_file) != 1){
    stop("length(ET_file) != 1; aka you don't have an ET file for this timestamp (or you have multiple)")
  } else if (length(sd_file) != 1){
    stop("length(sd_file) != 1; aka you don't have an uncertainty file for this timestamp (or you have multiple)")
  }
  
  read_resample_write <- function(file, type){
    # read, resample, and write
    print(paste0("Resampling ", type, " raster"))
    ET_raster <- read_resample(file)
    print(paste0("Wrtiting ", type, " raster"))
    writeRaster(ET_raster, here("data", "intermediate", "ECOSTRESS_cv", type, paste0(timestamp, ".tif")), "GTiff", overwrite=TRUE)
  }
  
  read_resample_write(ET_file, "ET")
  read_resample_write(sd_file, "sd")
  read_resample_write(T_file, "T")
  read_resample_write(PET_file, "PET")
  
  print(paste("Time elapsed for this timestamp:", Sys.time() - time))
}

# make the new directories
dir.create(here("data", "intermediate", "ECOSTRESS_cv"))
dir.create(here("data", "intermediate", "ECOSTRESS_cv", "ET"))
dir.create(here("data", "intermediate", "ECOSTRESS_cv", "sd"))
dir.create(here("data", "intermediate", "ECOSTRESS_cv", "T"))
dir.create(here("data", "intermediate", "ECOSTRESS_cv", "PET"))

# for loop so you can keep track of when it blew up
# for (i in 1:length(unique_timestamps)){
#   print(paste("On timestamp number", i))
#   process(unique_timestamps[i])
# }

# lapply so it goes fast!!
# lapply(unique_timestamps, process)

# parallel so it goes even faster!!!
no_cores <- detectCores() - 1# Calculate the number of cores
print(no_cores)
# no_cores <- 32
cl <- makeCluster(no_cores, type="FORK") # Initiate cluster
parLapply(cl, unique_timestamps, process)
stopCluster(cl)
