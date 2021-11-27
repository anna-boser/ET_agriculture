# This file makes ET averages for the time intervals. 
# Note that randomness would need to be inserted before this step in order to bootstrap. 

# Anna Boser November 5, 2021

from pyprojroot import here
import rasterio
from rasterio.plot import show
import datetime
import numpy as np
import pandas as pd
import csv
import time
from osgeo import gdal#, gdalconst
# import matplotlib.pyplot as plt

# read in raster
start = time.time()
img = gdal.Open(str(here("./data/intermediate/ECOSTRESS/ETinst_OGunits_1.tif")))
array = img.ReadAsArray() #date lon lat
end = time.time()
print(end - start)

# since I was unable to get all the rasters to merge together in R I do it here: 
for i in range(2, 20): # should be 2,20 for in cluster
    print(i)
    start = time.time()
    img = gdal.Open(str(here("./data/intermediate/ECOSTRESS/ETinst_OGunits_{}.tif".format(i))))
    a = img.ReadAsArray()
    array = np.concatenate([array, a])
    end = time.time()
    print(end - start)

array[array < -20] = np.NaN # NaN values are a very large negative number. I leave room for some negative values in case of condensation

# average by time interval

# get dates
date_list = pd.read_csv(here("./data/intermediate/ECOSTRESS/dates.csv"))['x'].tolist()
date_list = [datetime.datetime.strptime(d, "%Y-%m-%d").date() for d in date_list]

# I need to do that thing where I take the first 14 days of the year and put it at the end of the year 
imgs_2019 = array[[d.year==2019 for d in date_list]]
imgs_2020 = array[[d.year==2020 for d in date_list]]

date_array = np.array(date_list)
dates_2019 = date_array[[d.year==2019 for d in date_list]]
dates_2020 = date_array[[d.year==2020 for d in date_list]]

d_19_to_20 = dates_2019[[d < datetime.date(day = 15, month = 1, year = 2019) for d in dates_2019]]
d_19_to_20 = np.array([d.replace(year = 2020) for d in d_19_to_20])
d_20_to_21 = dates_2020[[d < datetime.date(day = 15, month = 1, year = 2020) for d in dates_2020]]
d_20_to_21 = np.array([d.replace(year = 2021) for d in d_20_to_21])

imgs_2019 = np.concatenate([imgs_2019[[d >= datetime.date(day = 15, month = 1, year = 2019) for d in dates_2019]], imgs_2019[[d < datetime.date(day = 15, month = 1, year = 2019) for d in dates_2019]]])
imgs_2020 = np.concatenate([imgs_2020[[d >= datetime.date(day = 15, month = 1, year = 2020) for d in dates_2020]], imgs_2020[[d < datetime.date(day = 15, month = 1, year = 2020) for d in dates_2020]]])

dates_2019 = np.concatenate([dates_2019[[d >= datetime.date(day = 15, month = 1, year = 2019) for d in dates_2019]], d_19_to_20])
dates_2020 = np.concatenate([dates_2020[[d >= datetime.date(day = 15, month = 1, year = 2020) for d in dates_2020]], d_20_to_21])

array = np.concatenate([imgs_2019, imgs_2020])

date_list = np.concatenate([dates_2019, dates_2020])

# average by time interval

# these are the start dates of the wanted time intervals
date_starts = [datetime.date(day = 15, month = m, year = y) for y in range(2019,2021) for m in [1,3,5,7,9,11]]
del date_starts[1]

# index of image on or nearest after start date
start_index = [date_list.index(min([i for i in date_list if i >= date_start], key=lambda x:x-date_start)) + 1 for date_start in date_starts] # plus one since bands are 1 indexed

# index of image on or nearest previous to start date + 61 days (this is for a non-inclusive index range so this date will be the first one not to be included in a subset)
end_index = [date_list.index(min([i for i in date_list if i <= date_start + datetime.timedelta(days=61)], key=lambda x:date_start+datetime.timedelta(days=61)-x)) + 1 for date_start in date_starts] # plus one since bands are 1 indexed

#average by time interval
newarray = np.stack([array[start_index[i]:end_index[i]].mean(axis = 0) for i in range(0,len(start_index))], axis=0)
newarray.shape

# save 

# get metadata
metadata = img.profile
metadata['count'] = 11 # 11 different time intervals

# write your new raster
with rasterio.open(here("./data/intermediate/ECOSTRESS/ETinst_yeargrouped_avg.tif"), 'w', **metadata) as dst:
    dst.write(newarray)