# this script checks the distribution of when ECOSTRESS images are available 
# by checking their file names in the code/1_download_data/2_ECOSTRESS/2_download_links folder

# Anna Boser October 18, 2021

library(here)
library(stringr)
library(lubridate)
library(ggplot2)

files <- list.files(here("code", "1_download_data", "2_ECOSTRESS", "2_download_links"), full.names = TRUE)

times <- c()
for (file in files){
  newlinks <- read.csv(file, header = FALSE)$V1
  # print(length(newlinks))
  # print(length(unique(newlinks)))
  newtimes <- str_extract(newlinks, regex('(?<=_doy)[0-9]*(?=_aid0001.tif)'))
  # print(length(newtimes))
  # print(length(unique(newtimes)))
  times <- c(times, newtimes)
}

getdate <- function(nums){
  
  year <- substr(nums, 1, 4)
  doy <- substr(nums, 5, 7) %>% as.numeric()
  hhmmss <- substr(nums, 8, 13)
  date <- as.Date(doy - 1, origin = paste0(year, "-01-01"))
  dt <- ymd_hms(paste(date, hhmmss), tz = "UTC") %>% with_tz("America/Los_Angeles")
  
  return(dt)
}

all_dates <- do.call(c, lapply(times, getdate))

data.frame(dt = all_dates[year(all_dates) %in% c(2019, 2020)]) %>% # only 2019 and 2020
  ggplot() +
  geom_point(aes(x = month(dt) + day(dt)/30 + hour(dt)/(24*30), y = hour(dt) + minute(dt)/60, col = as.factor(year(dt)))) +
  xlab("Month") + 
  ylab("Hour")  +
  theme_bw() +
  theme(legend.title = element_blank())+ 
  geom_vline(xintercept=1.5, linetype="dashed", color = "red") + 
  geom_vline(xintercept=3.5, linetype="dashed", color = "red") + 
  geom_vline(xintercept=5.5, linetype="dashed", color = "red") + 
  geom_vline(xintercept=7.5, linetype="dashed", color = "red") + 
  geom_vline(xintercept=9.5, linetype="dashed", color = "red") + 
  geom_vline(xintercept=11.5, linetype="dashed", color = "red") 
