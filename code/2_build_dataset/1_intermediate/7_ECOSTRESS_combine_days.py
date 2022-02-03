# This file combines images taken on the same day but in different locations into the same file. 
# This will help us have fewer individual files when taking the average later. 

# Anna Boser and Kelly Caylor, February 3, 2022

import os
import datetime
from pyprojroot import here
import pandas as pd
from osgeo import gdal

# list all the ECOSTRESS files
file_list = [s for s in os.listdir(str(here("./data/raw/ECOSTRESS/"))) if s.endswith('.tif')]
# file_list = [str(here("./data/raw/ECOSTRESS/")) + file for file in file_list]

# function to parse the file names to return the timestamp or whether it's an ET or uncertainty measure
def parse_filename(file_string,result='timestamp'):
    (root_string,variable,method,source,raster_type,timestamp,end_string) = file_string.split('_')
    if result == 'timestamp':
        return datetime.datetime.strptime(timestamp[3:], "%Y%j%H%M%S")
    elif result == 'raster_type':
        return raster_type
    else:
        return None    

# function to merge files together using GDAL. To be used on files with same timestamp and type
def merge_files(file_list, output=None):
    if output:
        file_string = " ".join(file_list)
        print("Merging {files}".format(files=file_string))
        print("Output {output}".format(output=output))
        command = "gdal_merge.py -o {output} -of gtiff ".format(output=output) + file_string
    else:
        raise ValueError("Must provide output filename as argument")
    print(os.popen(command).read())
    return None

# create a dataframe with each file and time and type information
df = pd.DataFrame(file_list, columns=['name'])
df['timestamp'] = df['name'].apply(parse_filename)
df['raster_type'] = df['name'].apply(parse_filename, result='raster_type')
df['year'] = df['timestamp'].apply(lambda x: x.year)
df['doy'] = df['timestamp'].apply(lambda x: x.timetuple().tm_yday)
df['fullname'] = df['name'].apply(lambda x: str(here("./data/raw/ECOSTRESS/")) + "/" + x)

# get the unique days and raster types you need to create a merged raster for
years = df.year.unique()
days = df.doy.unique()
raster_types = df.raster_type.unique()

# create the folder to save the merged outputs if it doesn't exist yet
outdir = str(here("./data/intermediate/ECOSTRESS/day_merged"))
if not os.path.exists(outdir):
    os.makedirs(outdir)

for year in years:
    for day in days:
        for raster_type in raster_types:
            
            # define the name of the file to save to
            merged_output_filename = "merged_{year}_{doy}_{raster_type}.tif".format(
                raster_type=raster_type,
                year=year,
                doy=day)
            
            # select the files with the correct time and raster type
            select_file_list = (df[
                (df['year'] == year) & 
                (df['doy'] == day) & 
                (df['raster_type'] == raster_type)
            ].fullname.to_list())
            
            # merge and save
            merge_files(select_file_list, output= outdir + "/" + merged_output_filename)