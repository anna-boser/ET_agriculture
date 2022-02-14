import os
import datetime
from pyprojroot import here
import pandas as pd
from osgeo import gdal
import numpy as np

# list all the ECOSTRESS files
file_list = [s for s in os.listdir(str(here("./data/raw/ECOSTRESS/"))) if s.endswith('.tif')]

# reproject each raster to the CA_grid's GeoTransform
CA_grid = gdal.Open(str(here("./data/intermediate/CA_grid.tif")))

# get the pixel size of the CA grid
CA_grid.GetGeoTransform() # https://svn.osgeo.org/gdal/trunk/autotest/alg/reproject.py

# make a new location for the reprojected images
outdir = str(here("./data/intermediate/ECOSTRESS/resampled/"))
if not os.path.exists(outdir):
    os.makedirs(outdir)

# define function to change pixel size
def CA_pixel(file):
    input_dir = str(here("./data/raw/ECOSTRESS/"))
    output_dir = str(here("./data/intermediate/ECOSTRESS/resampled/"))
    gdal.Warp(output_dir + "/" + file, input_dir + "/" + file, xRes=0.0006309954707866042, yRes=0.0006309954708085768) # https://stackoverflow.com/questions/7719651/how-can-i-change-the-resolution-of-a-raster-using-gdal
    return None

for file in file_list: 
    CA_pixel(file)
    
# function to parse the file names to return the timestamp or whether it's an ET or uncertainty measure
def parse_filename(file_string,result='timestamp'):
    (root_string,variable,method,source,raster_type,timestamp,end_string) = file_string.split('_')
    if result == 'timestamp':
        return datetime.datetime.strptime(timestamp[3:], "%Y%j%H%M%S")
    elif result == 'raster_type':
        return raster_type
    else:
        return None   
    
# create a dataframe with each file and time and type information
df = pd.DataFrame(file_list, columns=['name'])
df['timestamp'] = df['name'].apply(parse_filename)
df['raster_type'] = df['name'].apply(parse_filename, result='raster_type')
df['year'] = df['timestamp'].apply(lambda x: x.year)
df['doy'] = df['timestamp'].apply(lambda x: x.timetuple().tm_yday)
df['fullname'] = df['name'].apply(lambda x: str(here("./data/intermediate/ECOSTRESS/resampled/")) + "/" + x)
df['monthday'] = df['timestamp'].apply(lambda x: int(str(x.month)+str(x.day).zfill(2)))

bins = [0, 115, 315, 515, 715, 915, 1115, 1300]
labels = ['NDJ', 'JFM', 'MAM', 'MJJ', 'JAS', 'SAN', 'NDJ']
df['monthgroup'] = pd.cut(df.monthday, bins, labels = labels, include_lowest = True, ordered = False)

# create the folder to save the merged outputs if it doesn't exist yet
outdir = str(here("./data/intermediate/ECOSTRESS/monthgroup_averaged"))
if not os.path.exists(outdir):
    os.makedirs(outdir)
    
# get the unique days and raster types you need to create a merged raster for
years = df.year.unique()
monthgroups = df.monthgroup.unique()
raster_types = df.raster_type.unique()

# function to average all the files together using GDAL
def gdal_calc_files(file_list, calc, output=None):
    if output:
        file_string = " ".join(file_list)
        # print("Averaging {files}".format(files=file_string))
        print("Output {output}".format(output=output))
        command = "/usr/local/bin/gdal_calc.py -A {file_string} --outfile {output} --extent=union --debug --calc={calc}".format(
            output=output, 
            file_string=file_string, 
            calc = calc)
        print("Command: {command}".format(command=command))
    else:
        raise ValueError("Must provide output filename as argument")
    print(os.popen(command).read())
    return None

# take the average an pixel count
for year in years:
    for monthgroup in monthgroups:
        for raster_type in raster_types:

            # select the files with the correct time and raster type
            select_file_list = (df[
                (df['year'] == year) & 
                (df['monthgroup'] == monthgroup) & 
                (df['raster_type'] == raster_type)
            ].fullname.to_list())
            
            # define the name of the avg file to save to
            merged_output_filename_avg = "avg_{year}_{monthgroup}_{raster_type}.tif".format(
                raster_type=raster_type,
                monthgroup=monthgroup,
                year=year)
            
            calc = "'numpy.average(A, axis=0)'"
            
            # average and save
            gdal_calc_files(select_file_list, calc, output=outdir + "/" + merged_output_filename_avg)