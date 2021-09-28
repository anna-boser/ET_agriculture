################################################################################
# This script downloads the 2010 and 2015 data on water consumption from the USGS 
# when is 2020 coming out? 
# where exactly does this data come from? The feds? because they didn't give it to me...

# This script actually doesn't work :) need to go to the links below and 
# download the data manually and put it in the right folder. 

# Anna Boser Sep 9 2021
################################################################################

library(here)

dir.create(here("data", "raw", "USGS_waterdata"))

# 2010
download.file(url = "https://waterdata.usgs.gov/ca/nwis/water_use?wu_year=2010&wu_area=County&wu_county=ALL&wu_category=IC&submitted_form=introduction&wu_county_nms=--ALL+Counties--&wu_category_nms=Irrigation%2C+Crop", 
              destfile = here("data", "raw", "USGS_waterdata", "2010"))

# 2015


download.file(url = "https://waterdata.usgs.gov/ca/nwis/water_use?wu_year=2015&wu_area=County&wu_county=ALL&wu_category=IC&submitted_form=introduction&wu_county_nms=--ALL+Counties--&wu_category_nms=Irrigation%2C+Crop", 
              destfile = here("data", "raw", "USGS_waterdata", "2015"))