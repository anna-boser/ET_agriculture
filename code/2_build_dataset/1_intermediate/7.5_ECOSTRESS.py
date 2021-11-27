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
import matplotlib.pyplot as plt
import math
# from os import listdir

# first figure out for each interval which substacks to read in 
# get dates
date_list = pd.read_csv(here("./data/intermediate/ECOSTRESS/dates.csv"))['x'].tolist()
date_list = [datetime.datetime.strptime(d, "%Y-%m-%d").date() for d in date_list]
date_starts = [datetime.date(day = 15, month = m, year = y) for y in range(2019,2021) for m in [1,3,5,7,9,11]]
del date_starts[1]

date_starts = [datetime.date(day = 15, month = m, year = y) for y in range(2019,2021) for m in [1,3,5,7,9,11]]
del date_starts[1]

# index of image on or nearest after start date
start_index = [date_list.index(min([i for i in date_list if i >= date_start], key=lambda x:x-date_start)) for date_start in date_starts] 

# index of image on or nearest previous to start date + 61 days (this is for a non-inclusive index range so this date will be the first not to be included in a subset)
end_index = [date_list.index(min([i for i in date_list if i <= date_start + datetime.timedelta(days=61)], key=lambda x:date_start+datetime.timedelta(days=61)-x)) + 1 for date_start in date_starts] 

# get metadata
img = rasterio.open(str(here("./data/intermediate/CA_grid.tif")))
metadata = img.profile

# the indices are a bit more complicated for the fifth (index 4) and eleventh (index 10) timesteps, so let's start with the others
for i in [0,1,2,3,5,6,7,8,9]:
    print("On time interval {}".format(i))
    start = time.time()
    
    # figure out which stacks you need 
    start = start_index[i]
    end = end_index[i]
    start_stack = math.floor(start/50) + 1 # plus once since the way I stored it is not zero indexed
    end_stack = math.floor((end-1)/50) + 1 #end-1 since end is non-inclusive
    print("Start_stack {}".format(start_stack))
    print("End_stack {}".format(end_stack))
    
    start = start - 50*(start_stack-1)
    end = end - 50*(start_stack-1)
    print(start)
    print(end)
    
    weights = []
    means = []
    for j in range(start_stack, end_stack+1): # plus one since inclusive
        print("Working on stack {}".format(j))

        # read in the required stacks
        stack = gdal.Open(str(here("./data/intermediate/ECOSTRESS/ETinst_OGunits_{}.tif".format(j))))
        a = stack.ReadAsArray()
        del stack
        print(a.shape)
        
        starter = start
        ender = min(end, a.shape[0]) # plus one to make it non-inclusive
        print(starter)
        print(ender)
        
        weights = weights + [ender - starter]
        print(weights)
        
        means = means + [np.nanmean(a[starter:ender], axis = 0)] # remember ender is not included
        print("successfully took mean of current stack")
        
        start = start - 50
        end = end - 50
        del a
        
    meanstack = np.stack(means, axis = 0)
    print(meanstack.shape)
    masked_data = np.ma.masked_array(meanstack, np.isnan(meanstack))
    average = np.ma.average(masked_data, axis=0, weights=weights)
    result = average.filled(np.nan)
    print(result.shape)
    
    # write your new raster
    with rasterio.open(str(here("./data/intermediate/ECOSTRESS/ETinst_yeargrouped_{}.tif".format(i))), 'w', **metadata) as dst:
        dst.write(result)
    
    end = time.time()
    print(end - start)
    