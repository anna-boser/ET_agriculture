# there is in all likelihood a bias going on where 
# (1) there could be contaminated pixels because they are close to irrigated areas/are irrigated themselves
# (2) the model is too heavily influenced by far away and dissimilar pixels and is extrapolating wrong into the central valley

# solutions: 
# (1) remove pixels that are close to (neighboring) agriculture, since these might be contaminated (and remove outliers since these are probably irrigated?) 
# (2) balance the dataset such that it is being trained only or mostly on similar/close pixels

library(here)
library(raster)
library(sf)
library(dplyr)
library(fasterize)
library(fread)
library(exactextractr)
library(data.table)
library(ggplot2)

surround_buff <- 10000 # 10km
ag_buff <- 500 # 500m
counterf_name <- "fveg_cv_gs_mm"

# Step 1: read in the flat DWR ag data for the central valley
ag <- st_read(here("data", "intermediate", "agriculture", "ag_indicator_shapefile", "ag_indicator_new_crs.shp"))
ag <- st_make_valid(ag)
st_write(ag, here("data", "intermediate", "agriculture", "ag_indicator_shapefile", "ag_indicator_new_crs_valid.shp"))
# ag <- st_read(here("data", "intermediate", "agriculture", "ag_indicator_shapefile", "ag_indicator_new_crs_valid.shp"))

# Step 2: remove any stray pixels using the ag_inc shapefile
ag_inc <- st_read(here("data", "raw", "shapefiles", "ag_inclusion.shp"))
ag_clean <- st_intersection(ag, ag_inc)
st_write(ag_clean, here("data", "intermediate", "agriculture", "ag_indicator_shapefile", "ag_indicator_clean.shp"))
# ag_sm <- st_crop(ag_clean, st_bbox(c(xmin = -120, xmax = -119.5, ymax = 38, ymin = 37), crs = st_crs(ag_clean)))

# calculate how much land is covered by ag
area <- st_area(ag_clean)
write.csv(area, here("data", "intermediate", "agriculture", "ag_area_cv_m2.csv"))

# Step 3: make a buffer around the ag shapefile of the areas I want to keep
ag_surround <- st_buffer(ag_clean, surround_buff) # 10km

# Step 4: read in the CV shapefile and keep the overlap as the study area
cv <- st_read(here("data", "raw", "shapefiles", "cimis_CV", "cimis_CV.shp")) %>% st_transform(st_crs(ag_clean))
surround_inc <- st_intersection(ag_surround, cv)

# Step 5: make a buffer around the ag shapefile for pixels I want to discard due to proximity to ag
ag_buffer <- st_buffer(ag_clean, ag_buff) # 500m

# Step 6: Take the difference for acceptable areas for counterfactual dataset
counterf_allowed <- st_difference(surround_inc, ag_buffer)
dir.create(here("data", "intermediate", "counterf", "counterf_refined_loc"))
st_write(counterf_allowed, here("data", "intermediate", "counterf", "counterf_refined_loc", "counterf_refined_loc.shp"))

# Step 7: Get pixels that are covered
grid <- raster(here("data", "intermediate", "CA_grid_cv.tif"))
geoweights <- rbindlist(exactextractr::exact_extract(grid, counterf_allowed, progress = T, include_cell = T, include_xy = T))
geoweights$x <- round(geoweights$x, 7)
geoweights$y <- round(geoweights$y, 7)
# counterf_allowed_raster <- fasterize(counterf_allowed, grid) # all pixels even partially covered by ag should be marked
# writeRaster(counterf_allowed_raster, here("data", "intermediate", "counterf", "counterf_refined_loc.tif"), "GTiff", overwrite=TRUE)

# Step 8: read in a counterfactual dataset and only keep the pixels that are included in the refined category
counterf <- data.table::fread(here("data", "for_analysis", paste0(counterf_name, ".csv")))
counterf$x <- round(counterf$x, 7)
counterf$y <- round(counterf$y, 7)

counterf_filtered <- filter(counterf, paste(counterf$x, counterf$y) %in% paste(geoweights$x, geoweights$y))

# save
fwrite(counterf_filtered, here("data", "for_analysis", paste0(counterf_name, "_filtered", ag_buff, surround_buff, ".csv")))

# ggplot(counterf_filtered) + 
#   geom_raster(data = counterf_filtered, aes(x=x, y=y)) + 
#   geom_sf(data=ag_clean)






# ####################################################################################
# # This code is to remove outliers. 
# # After visually inspecting the simulated counterfactual (cdl) using the above dataset, 
# # it became clear that certain locations were likely contaminated and were irrigated. 
# # Therefore, here we screen for locations that are likely not natural land and get rid of them. 
# 
# data <- fread(here("data/for_analysis/counterfactual_cv_gs_mm.csv"))
# 
# # remove monthgroups
# data <- pivot_wider(data, names_from = c(monthgroup), values_from = c(ET, PET))
# 
# data$ET <- rowMeans(select(data, ET_2, ET_3, ET_4), na.rm = FALSE)
# data$PET <- rowMeans(select(data, PET_2, PET_3, PET_4), na.rm = FALSE)
# 
# data <- data %>% select(-ET_2, -ET_3, -ET_4, -PET_2, -PET_3, -PET_4)
# 
# # remove any NA values
# data <- filter(data, !(is.na(ET)))
# 
# # inspect <- filter(data, ET>2.5)
# 
# # library(ggplot2)
# # inspect %>%
# #   ggplot() +
# #   geom_point(aes(x = x, y = y, color = ET), size = .1) +
# #   scale_color_gradientn(name="ET (mm/day)", colours = c("darkgoldenrod4", "darkgoldenrod2", "khaki1", "lightgreen", "turquoise3", "deepskyblue3", "mediumblue", "navyblue", "midnightblue", "black")) +
# #   theme_void()
# 
# # After visual inspection, anything above 4 looks like it could plausibly be irrigated. 
# # This represents .1% of the data, so we feel that it is unlikely that we are biasing the natural counterfactual downward. 
# 
# # identify these locations and remove them from the dataset
# loc <- paste(filter(data, ET < 4)$x, filter(data, ET < 4)$y)
# 
# data2 <- fread(here("data/for_analysis/counterfactual_cv_gs_mm.csv"))
# data2 <- filter(data2, paste(data2$x, data2$y) %in% loc)
# 
# fwrite(data2, here("data", "for_analysis", "counterfactual_cv_gs_mm<4.csv"))
# 
# # anything above 4.5; .03%
# loc <- paste(filter(data, ET < 4.5)$x, filter(data, ET < 4.5)$y)
# 
# data2 <- fread(here("data/for_analysis/counterfactual_cv_gs_mm.csv"))
# data2 <- filter(data2, paste(data2$x, data2$y) %in% loc)
# 
# fwrite(data2, here("data", "for_analysis", "counterfactual_cv_gs_mm<4.5.csv"))
# 
# # anything above 5; .005% of the data
# loc <- paste(filter(data, ET < 5)$x, filter(data, ET < 5)$y)
# 
# data2 <- fread(here("data/for_analysis/counterfactual_cv_gs_mm.csv"))
# data2 <- filter(data2, paste(data2$x, data2$y) %in% loc)
# 
# fwrite(data2, here("data", "for_analysis", "counterfactual_cv_gs_mm<5.csv"))