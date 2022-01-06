# This script adds the PET variable to the time invarying dataframe

import rioxarray
from pyprojroot import here
import pandas as pd
from osgeo import gdal
import numpy as np
import pickle

# see https://gis.stackexchange.com/questions/358051/convert-raster-to-csv-with-lat-lon-and-value-columns
def datasetify(raster_path, varname):
    rds = rioxarray.open_rasterio(
        raster_path,
    )
    rds = rds.squeeze().drop("spatial_ref").drop("band")
    rds.name = varname
    df = rds.to_dataframe().reset_index()
    return df

# flatten other rasters and add them to the dataset
def add_columns(file, name):
    ar = gdal.Open(str(file)).ReadAsArray()
    if len(ar.shape) == 2:
        ar = ar.reshape(ar.shape[0]*ar.shape[1]) #flatten the array
        dataframe[name] = ar
    elif len(ar.shape) == 3:
        ar = ar.reshape(ar.shape[0], ar.shape[1]*ar.shape[2]) #flatten the array same as above
        ar = ar.reshape(ar.shape[0]*ar.shape[1]) # flatten again
        dataframe[name] = ar
    else: 
        raise Exception("Unexpected number of dimensions")

# read in the time invarying version
dataframe = pd.read_csv(str(here("./data/for_analysis/full_grid_time_invariant.csv")))

# add time varying variable PET 

month_group = np.array([0,1,2,3,4,5])

# repeat the dataframe once for each start date
repeated_month_group = np.repeat(month_group, dataframe.shape[0])
dataframe = pd.concat([dataframe]*len(month_group))
dataframe["start_date"] = repeated_month_group

# add PET and ET
add_columns(str(here("./data/intermediate/PET/PET_grouped_avg.tif")), 
                     "PET")

# save without ET
dataframe.to_csv(str(here("./data/for_analysis/full_grid_no_ET.csv")), index=False)
