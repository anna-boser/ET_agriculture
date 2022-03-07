# This script combines all the scripts created in 2,1 to make 
# (1) a dataset of the full grid
# (2) a dataset of only the counterfactual pixels
# (3) a dataset of only the ag pixels

import rioxarray
from pyprojroot import here
import pandas as pd
from osgeo import gdal
import numpy as np
import pickle

# initialize the dataset with ag data

# see https://gis.stackexchange.com/questions/358051/convert-raster-to-csv-with-lat-lon-and-value-columns
def datasetify(raster_path, varname):
    rds = rioxarray.open_rasterio(
        raster_path,
    )
    rds = rds.squeeze().drop("spatial_ref").drop("band")
    rds.name = varname
    df = rds.to_dataframe().reset_index()
    return df

dataframe = datasetify(str(here("./data/intermediate/agriculture/ag_indicator.tif")), 
               "agriculture")

dataframe

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

# add all time invarying variables

add_columns(str(here("./data/intermediate/counterf/counterf_indicator.tif")), 
           "counterfactual")

add_columns(str(here("./data/intermediate/topography/elevation.tif")), 
                     "elevation")

add_columns(str(here("./data/intermediate/topography/aspect.tif")), 
                     "aspect")

add_columns(str(here("./data/intermediate/topography/slope.tif")), 
                     "slope")

add_columns(str(here("./data/intermediate/CA_storie/CA_storie.tif")), 
                     "soil")

# save the time invarying version
dataframe.to_csv(str(here("./data/for_analysis/full_grid_time_invariant.csv")), index=False)

# add ET and PET


add_columns(str(here("./data/intermediate/PET/PET_grouped_0.tif")), 
                     "PET0")

add_columns(str(here("./data/intermediate/PET/PET_grouped_1.tif")), 
                     "PET1")

add_columns(str(here("./data/intermediate/PET/PET_grouped_2.tif")), 
                     "PET2")

add_columns(str(here("./data/intermediate/PET/PET_grouped_3.tif")), 
                     "PET3")

add_columns(str(here("./data/intermediate/PET/PET_grouped_4.tif")), 
                     "PET4")

add_columns(str(here("./data/intermediate/PET/PET_grouped_5.tif")), 
                     "PET5")

add_columns(str(here("./data/intermediate/ECOSTRESS/ET_mean/0.tif")), 
                     "ET0")

add_columns(str(here("./data/intermediate/ECOSTRESS/ET_mean/1.tif")), 
                     "ET1")

add_columns(str(here("./data/intermediate/ECOSTRESS/ET_mean/2.tif")), 
                     "ET2")

add_columns(str(here("./data/intermediate/ECOSTRESS/ET_mean/3.tif")), 
                     "ET3")

add_columns(str(here("./data/intermediate/ECOSTRESS/ET_mean/4.tif")), 
                     "ET4")

add_columns(str(here("./data/intermediate/ECOSTRESS/ET_mean/5.tif")), 
                     "ET5")

# save the ET PET version
dataframe.to_csv(str(here("./data/for_analysis/full_grid_not_tidy.csv")), index=False)

# filter only agriculture
agriculture = dataframe.query('agriculture==1')

# save
agriculture.to_csv(str(here("./data/for_analysis/agriculture_not_tidy.csv")), index=False)

# filter only counterfactual
counterfactual = dataframe.query('counterfactual==1')

# save
counterfactual.to_csv(str(here("./data/for_analysis/counterfactual_not_tidy.csv")), index=False)


# add time varying variables (PET and ET)

# # first read in the start dates that each layer corresponds to
# with open(str(here("./data/intermediate/start_dates.pkl")), 'rb') as f:
#     start_date = pickle.load(f)

# # repeat the dataframe once for each start date
# repeated_start_date = np.repeat(start_date, dataframe.shape[0])
# dataframe = pd.concat([dataframe]*len(start_date))
# dataframe["start_date"] = repeated_start_date

# # add PET and ET
# add_columns(str(here("./data/intermediate/PET/PET_rolling_avg.tif")), 
#                      "PET")

# # save without ET
# dataframe.to_csv(str(here("./data/for_analysis/full_grid_no_ET.csv")), index=False)

# add_columns(str(here("./data/intermediate/ECOSTRESS/ETinst_rolling_average.tif")), 
#                      "ET")

# # save the full dataset
# dataframe.to_csv(str(here("./data/for_analysis/full_grid.csv")), index=False)

# # filter the dataset to only agriculture and save 
# ag = dataframe.loc[(dataframe.agriculture == 1)]
# ag.to_csv(here("./data/for_analysis/agriculture.csv"), index=False)

# # filter the dataset to only vegetation and save
# veg = dataframe.loc[(dataframe.counterfactual == 1)]
# veg.to_csv(str(here("./data/for_analysis/counterfactual.csv")), index=False)