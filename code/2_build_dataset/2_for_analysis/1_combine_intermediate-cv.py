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

dataframe = datasetify(str(here("./data/intermediate/agriculture/ag_indicator_cv.tif")), 
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

################################################################
# add all time invarying variables

add_columns(str(here("./data/intermediate/counterf/counterf_indicator_cv.tif")), 
           "counterfactual")

# add the extra counterfactual datasets 
add_columns(str(here("./data/intermediate/counterf/fveg_indicator_cv.tif")), 
           "fveg")
add_columns(str(here("./data/intermediate/counterf/potected_areas/CPAD123_indicator_cv.tif")), 
           "cpad")
add_columns(str(here("./data/intermediate/counterf/cpad_fveg_indicator_cv.tif")), 
           "cpad_fveg")
add_columns(str(here("./data/intermediate/counterf/cdl_fveg_indicator_cv.tif")), 
           "cdl_fveg")

add_columns(str(here("./data/intermediate/topography/elevation_cv.tif")), 
                     "elevation")

add_columns(str(here("./data/intermediate/topography/aspect_cv.tif")), 
                     "aspect")

add_columns(str(here("./data/intermediate/topography/slope_cv.tif")), 
                     "slope")

add_columns(str(here("./data/intermediate/CA_storie/CA_storie_cv.tif")), 
                     "soil")

add_columns(str(here("./data/intermediate/water/water21_cv.tif")), 
                     "water21")

add_columns(str(here("./data/intermediate/water/water51_cv.tif")), 
                     "water51")

add_columns(str(here("./data/intermediate/water/water101_cv.tif")), 
                     "water101")

add_columns(str(here("./data/intermediate/water/water201_cv.tif")), 
                     "water201")
################################################################

# save the time invarying version
dataframe.to_csv(str(here("./data/for_analysis/full_grid_time_invariant_cv.csv")), index=False)

################################################################

# add ET and PET

add_columns(str(here("./data/intermediate/PET/PET_grouped_0_cv.tif")), 
                     "PET0")

add_columns(str(here("./data/intermediate/PET/PET_grouped_1_cv.tif")), 
                     "PET1")

add_columns(str(here("./data/intermediate/PET/PET_grouped_2_cv.tif")), 
                     "PET2")

add_columns(str(here("./data/intermediate/PET/PET_grouped_3_cv.tif")), 
                     "PET3")

add_columns(str(here("./data/intermediate/PET/PET_grouped_4_cv.tif")), 
                     "PET4")

add_columns(str(here("./data/intermediate/PET/PET_grouped_5_cv.tif")), 
                     "PET5")

add_columns(str(here("./data/intermediate/ECOSTRESS_cv/ET_mean/0.tif")), 
                     "ET0")

add_columns(str(here("./data/intermediate/ECOSTRESS_cv/ET_mean/1.tif")), 
                     "ET1")

add_columns(str(here("./data/intermediate/ECOSTRESS_cv/ET_mean/2.tif")), 
                     "ET2")

add_columns(str(here("./data/intermediate/ECOSTRESS_cv/ET_mean/3.tif")), 
                     "ET3")

add_columns(str(here("./data/intermediate/ECOSTRESS_cv/ET_mean/4.tif")), 
                     "ET4")

add_columns(str(here("./data/intermediate/ECOSTRESS_cv/ET_mean/5.tif")), 
                     "ET5")

# save the ET PET version
dataframe.to_csv(str(here("./data/for_analysis/full_grid_not_tidy_cv.csv")), index=False)

# filter only agriculture
agriculture = dataframe.query('agriculture==1')

# save
agriculture.to_csv(str(here("./data/for_analysis/agriculture_not_tidy_cv.csv")), index=False)

# filter only counterfactual
counterfactual = dataframe.query('counterfactual==1')

# save
counterfactual.to_csv(str(here("./data/for_analysis/counterfactual_not_tidy_cv.csv")), index=False)

# filter only fveg
fveg = dataframe.query('fveg==1')

# save
fveg.to_csv(str(here("./data/for_analysis/fveg_not_tidy_cv.csv")), index=False)

# filter only cpad
cpad = dataframe.query('cpad==1')

# save
cpad.to_csv(str(here("./data/for_analysis/cpad_not_tidy_cv.csv")), index=False)

# filter only cpad_fveg
cpad_fveg = dataframe.query('cpad_fveg==1')

# save
cpad_fveg.to_csv(str(here("./data/for_analysis/cpad_fveg_not_tidy_cv.csv")), index=False)

# filter only cdl_fveg
cdl_fveg = dataframe.query('cdl_fveg==1')

# save
cdl_fveg.to_csv(str(here("./data/for_analysis/cdl_fveg_not_tidy_cv.csv")), index=False)



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