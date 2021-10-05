# ET_agriculture
 
This repository is for an analysis of the effect of ET on agriculture as witnessed by differences in ECOSTRESS ET estimates over land cover and crop types. 
See report from JPL 2021 internship: https://docs.google.com/document/d/1xOjTGxKnkD_1tZrXiKZeYXzrA0Pmw3cboQdNA6kfm3U/edit?usp=sharing

## Structure and Contents

This repository is organized into two folders. The data folder contains raw and intermediate datasets, as well as final datasets used in the analysis. The code folder consists of code to (1) download data, (2) process the data into the intermediate and final datasets, (3) conduct analyses on the final data. The code folder is numbered in order of folders that are completed sequentially, and the numbers listed next to the data folders and data files correspond to the number of the code file used to create it. 



* data (1,0) : all data is listed in the .gitignore and is thus not stored on github. To retrieve data in its final form without using the given code to direct the raw data from its original source, please refer to *this drive folder*

    * raw (1,0): all raw data, found at given urls and retrieved using scripts in **code/download_data**
        * shapefiles (1,1): folder of shapefiles used to make APPEEARS requests for ECOSTRESS data (https://www.census.gov/geographies/mapping-files/time-series/geo/carto-boundary-file.html)
            * counties_5m (1,1):  (https://www2.census.gov/geo/tiger/GENZ2018/shp/cb_2018_us_nation_5m.zip)
            * county_shapefiles (1,1): Single county shapefiles
            * CIMIS_ETo: boundaries of ETo regions as described https://cimis.water.ca.gov/App_Themes/images/etozonemap.jpg. Obtained through personal correspondance with Ricardo.Trezza@water.ca.gov and DWRCIMISPublicContact@water.ca.gov. 
            * Hydrologic_Regions: California hydrologic regions accessed at https://atlas-dwr.opendata.arcgis.com/datasets/2a572a181e094020bdaeb5203162de15_0/explore?location=36.394054%2C-119.270000%2C6.70
            * Groundwater_basins: from https://gis.data.ca.gov/datasets/b5325164abf94d5cbeb48bb542fa616e_0/explore
        * ECOSTRESS (1,2): ECOSTRESS images obtained using the Appeears tool (https://lpdaacsvc.cr.usgs.gov/appeears/task/area). In order to obtain these files, a request is first made on appears using the county shapefiles (code folder 1_2_1). In order to easily download the data into appropriate county level folders once they are ready, either use the appeears interface or code 1_2 in the code folder. 
        * CDL (1,3)
            * CDL* (1,3): the CDL layer for every year needed (2019 and 2020)
            * code_dictionary_noncrop: manually pulled from https://www.nass.usda.gov/Research_and_Science/Cropland/metadata/2020_cultivated_layer_metadata.htm
            * code_dictionary_crops: manually pulled from https://www.nass.usda.gov/Research_and_Science/Cropland/metadata/2020_cultivated_layer_metadata.htm
        * USGS_waterdata
            * 2015: https://waterdata.usgs.gov/ca/nwis/water_use?wu_year=2015&wu_area=County&wu_county=ALL&wu_category=IC&submitted_form=introduction&wu_county_nms=--ALL+Counties--&wu_category_nms=Irrigation%2C+Crop
            * 2010: https://waterdata.usgs.gov/ca/nwis/water_use?wu_year=2010&wu_area=County&wu_county=ALL&wu_category=IC&submitted_form=introduction&wu_county_nms=--ALL+Counties--&wu_category_nms=Irrigation%2C+Crop
        * DWR_crop (1,5): https://data.cnra.ca.gov/dataset/statewide-crop-mapping
        * NED: National Elevations Datatset from USGS; 30m resolution. Downloaded from the geospatial data gateway by selecting California as the study area. https://gdg.sc.egov.usda.gov//

        
    * intermediate (1,0)
        * CDL_code_dictionary.csv (2,1,1): code dictionary decoding what land cover the CDL raster values stand for. Also contains some binning and grouping of land cover types. 
        * CDL+ECOSTRESS (2,1,2)
            * by_county
            * full
            * subset
            
    * for_analysis (1,0)
        * county_land_cover.csv (2,2,1)
        * CDL+ECOSTRESS.csv (2,2,2): *important* these datasets have had all latent heat values converted to water equivalents. 
        * CDL+ECOSTRESS_subset.csv (2,2,2): a random one hundredth of the above dataset for testing
        * county_water.csv (2,2,3)
        * crop_water.csv (2,2,4)
    
    
* code: all code for data download, processing, and analysis. 

    * 1_download_data:download data found in **data/raw/**
        * 0_repo_structure.R: create the basic repository structure 
        * 1_download_shapefiles.R: Download county shapefile and create the required individual county shapefiles
        * 2_ECOSTRESS
            * 0_repo_structure.R: create the basic repository structure of data/1_2_ECOSTRESS
            * 1_APPEEARS_requests: documentation on the appeears (https://lpdaacsvc.cr.usgs.gov/appeears/task/area) requests which can be copied to make the requests again
            * 2_download_links: links provided by appeears that need to be downloaded
            * 3_download_scripts: 
                * Generic-download.sh: template to download the links listed in 2_download_links. Note to position oneself in the correct download folder when running these scripts (ex cd data/1_2_ECOSTRESS/Kings). Appeears account and password is needed. 
                * by_county: a folder of scripts to download for each county
        * 3_CDL.R: Download years 2018-2020 of the Cropland Data Layer
        * 4_USGS_waterdata.R: Supposed to download the county level California irrigation data from the USGS. SCRIPT NOT FUNCTIONAL: DOWNLOAD MANUALLY and then break up into metadata (first few lines of data) and data
        * 5_DWR_crop.R: Download the 2018 crop map shapefile of California in 18 from the Department of Water Resources
        
    * 2_build_dataset: create data in **data/intermediate** and **data/for_analysis**
        * 1_intermediate: create data in **data/intermediate**
            * 1_CDL_code_dictionary.R: create the code dictionary for crop types
        * 2_for_analysis: create data in **data/for_analysis**
            * *1_county_land_cover*
            * *2_CDL+ECOSTRESS*
            * *3_county_water_use_comparison*
            * *4_crop_water_use_comparison*
            
    * 3_analysis: conduct analyses on final dataset(s)
        * 0_scratch: figures and tests done along the way that do not make it into the final results
            * 1_USGS_county_irrigation.Rmd: make some maps of the USGS county irrigation data
            * 2_CDL_DWR_USGS_crop_compare.Rmd: compare different land use data
        * 1_final: final results for the resulting paper. Written in Rmd; datasets used listed, 
            * *1_county_land_cover.Rmd: county_land_cover.csv (2,2,1)*
            * *2_CDL+ECOSTRESS.Rmd: CDL+ECOSTRESS.csv (2,2,2)*
            * *3_validation.Rmd: county_water.csv (2,2,3), crop_water.csv (2,2,4)*
        
        