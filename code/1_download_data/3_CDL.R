################################################################################
# This script downloads the 2018, 2019, and 2020 Cropland Data Layers

# Anna Boser Sep 9 2021
################################################################################

library(here)

unzip <- function(file, exdir, .file_cache = FALSE) { #the normal unzip doesn't work well with large files. 
  
  if (.file_cache == TRUE) {
    print("decompression skipped")
  } else {
    
    # Set working directory for decompression
    # simplifies unzip directory location behavior
    wd <- getwd()
    setwd(exdir)
    
    # Run decompression
    decompression <-
      system2("unzip",
              args = c("-o", # include override flag
                       file),
              stdout = TRUE)
    
    # uncomment to delete archive once decompressed
    # file.remove(file) 
    
    # Reset working directory
    setwd(wd); rm(wd)
    
    # Test for success criteria
    # change the search depending on 
    # your implementation
    if (grepl("Warning message", tail(decompression, 1))) {
      print(decompression)
    }
  }
}   

download_extract <- function(url, directory, new_folder){
  dir.create(here(directory, new_folder))
  destination <- here(directory, new_folder, paste0(new_folder, ".zip"))
  download.file(url, destination)
  unzip(destination, exdir = here(directory, new_folder))
  unlink(destination)
}

options(timeout = max(30000, getOption("timeout"))) #timeout for download.file is 60s by default; not enough for large files

dir.create(here("data", "raw", "CDL"))
years <- 2018:2020 # change to adjust the number of years you want to include

for (year in years){
  download_extract(url = paste0("https://www.nass.usda.gov/Research_and_Science/Cropland/Release/datasets/", year, "_30m_cdls.zip"),
                   directory = here("data", "raw", "CDL"),
                   new_folder = paste0("CDL", year))
}


