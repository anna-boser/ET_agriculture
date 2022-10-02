# Here we create several different counterfactual datasets and compare them to be
# used in analysis to ensure no data leakage. 

library(here)

fveg <- raster(here("data", "intermediate", "counterf", "fveg_indicator_cv.tif"))
cpad <- raster("data/intermediate/counterf/potected_areas/CPAD123_indicator_cv.tif")
cdl <- raster(here("data", "intermediate", "counterf", "counterf_indicator_cv.tif"))

# remove what's not fveg from CPAD. Also serves to remove the unlikely ag pixel
cpad_fveg <- cpad
values(cpad_fveg) <- ifelse(values(cpad)&values(fveg) == 1, 1, NA)
# plot(cpad_fveg) # removes stuff mostly in the periphery -- likely forest. 

writeRaster(cpad_fveg, here("data", "intermediate", "counterf", "cpad_fveg_indicator_cv.tif"), "GTiff", overwrite=TRUE)

# worst of both worlds...
cdl_fveg <- fveg
values(cdl_fveg) <- ifelse(values(cdl)&values(fveg) == 1, 1, NA)

writeRaster(cpad_fveg, here("data", "intermediate", "counterf", "cdl_fveg_indicator_cv.tif"), "GTiff", overwrite=TRUE)