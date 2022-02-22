# This is code adapted from https://www.urbandemographics.org/post/figures-map-layers-r/
# and is used to map the different layers of data used in my project

# Anna Boser Nov 8, 2021

library(easypackages)
library(here)
library(latex2exp)
easypackages::packages("sf",
                       "raster",
                       "stars",
                       "r5r",
                       "geobr",
                       "aopdata",
                       "gtfs2gps",
                       "ggplot2",
                       "osmdata",
                       #                        "h3jsr",
                       "viridisLite",
                       "ggnewscale",
                       "dplyr",
                       "magrittr",
                       prompt = FALSE
)

# Functions to tilt sf
# Original function created by Stefan Jünger.

rotate_data <- function(data, x_add = 0, y_add = 0) {
  
  # shear_matrix <- function(){ matrix(c(1,1,1,1), 2, 2) }
  shear_matrix <- function(){ matrix(c(2, 1.2, 0, 1), 2, 2) }
  # rotate_matrix <- function(x){ 
  #   matrix(c(1,1,1,1), 2, 2) 
  # }
  
  rotate_matrix <- function(x){
    matrix(c(cos(x), sin(x), -sin(x), cos(x)), 2, 2)
  }
  data %>% 
    dplyr::mutate(
      geometry = .$geometry * shear_matrix() * rotate_matrix(pi/20) + c(x_add, y_add)
    )
}

rotate_data_geom <- function(data, x_add = 0, y_add = 0) {
  shear_matrix <- function(){ matrix(c(2, 1.2, 0, 1), 2, 2) }
  
  rotate_matrix <- function(x) { 
    matrix(c(cos(x), sin(x), -sin(x), cos(x)), 2, 2) 
  }
  data %>% 
    dplyr::mutate(
      geom = .$geom * shear_matrix() * rotate_matrix(pi/20) + c(x_add, y_add)
    )
}

# Load data
# We’ll be using a few data sets available from the packages used here. 
# The first thing we need to do is to load the data and crop them to make sure they have the same extent.

# California
CA_grid <- raster(here("data", "intermediate", "CA_grid.tif"))
CA <- st_read(here("data", "raw", "shapefiles", "california", "california.shp")) %>% st_transform(st_crs(CA_grid))

# elevation (terrain)
dem <- raster(here("data", "intermediate", "topography", "elevation.tif"))
dem <- aggregate(dem, fact=20)
dem <- st_as_sf(rasterToPolygons(dem, na.rm = TRUE, dissolve = TRUE))
dem <- dem[lengths(st_within(dem, CA))>0,]
# saveRDS(dem, here("dem_ploter.Rds"))

# agriculture
ag <- st_read(here("data", "intermediate", "agriculture", "ag_indicator_shapefile", "ag_indicator_new_crs.shp"))

# vegetation/counterfactual
veg<- raster(here("data", "intermediate", "counterf", "counterf_indicator.tif"))
veg <- aggregate(veg, fact=20)
veg <- st_as_sf(rasterToPolygons(veg, na.rm = TRUE, dissolve = TRUE))
# saveRDS(veg, here("veg_ploter.Rds"))

# soil
soil <- raster(here("data", "intermediate", "CA_storie", "CA_storie.tif"))
soil <- aggregate(soil, fact=20)
soil <- st_as_sf(rasterToPolygons(soil, na.rm = TRUE, dissolve = TRUE))
soil <- soil[lengths(st_within(soil, CA))>0,]
# saveRDS(soil, here("soil_ploter.Rds"))

# PET
pet <- raster(here("data", "intermediate", "PET", "PET_rolling_avg.tif"))
pet <- aggregate(pet, fact=20)
pet <- st_as_sf(rasterToPolygons(pet, na.rm = TRUE, dissolve = TRUE))
pet <- pet[lengths(st_within(pet, CA))>0,]
# saveRDS(pet, here("pet_ploter.Rds"))

# ET
et <- raster(here("data", "intermediate", "ECOSTRESS", "ET_mean_by_year", "4-2020.tif"))
et <- aggregate(et, fact=20)
et <- st_as_sf(rasterToPolygons(et, na.rm = TRUE))
# saveRDS(et, here("et_ploter.Rds"))

# save.image(file=here("plotter.RData"))

### plot  ----------------

# parameters for the annotation
x = -169
color = 'gray40'
y_int = 10

temp1 <- ggplot() +
  
  # agriculture
  geom_sf(data = ag %>% rotate_data(), color= NA, fill='blue3', size=.1, alpha=.8) +
  annotate("text", label='Agriculture', x=x, y= 69, hjust = 0, color=color) +
  geom_sf(data = CA %>% rotate_data(), color='gray50', fill=NA, size=.1) +
  
  # vegetation/counterfactual
  geom_sf(data = veg %>% rotate_data(y_add = y_int*1), color= NA, fill='green4', size=.1, alpha=.8) +
  annotate("text", label=TeX('Vegetation \n counterfactual'), x=x, y= 69 + y_int*1, hjust = 0, color=color) +
  geom_sf(data = CA %>% rotate_data(y_add = y_int*1), color='gray50', fill=NA, size=.1) +
  
  # PET
  geom_sf(data = pet %>% rotate_data(y_add = y_int*2), aes(fill = PET_rolling_avg), color=NA, show.legend = FALSE) +
  scale_fill_distiller(palette = "YlGnBu", direction = 1) +
  annotate("text", label='PET', x=x, y= 69 + y_int*2, hjust = 0, color=color) +
  geom_sf(data = CA %>% rotate_data(y_add = y_int*2), color='gray50', fill=NA, size=.1) +
  
  # terrain
  new_scale_fill() + 
  new_scale_color() +
  geom_sf(data = dem %>% rotate_data(y_add = y_int*3), aes(fill = elevation), color=NA, show.legend = FALSE) +
  scale_fill_distiller(palette = "PuBuGn", direction = 1) +
  annotate("text", label='Terrain', x=x, y= 69 + y_int*3, hjust = 0, color=color) +
  geom_sf(data = CA %>% rotate_data(y_add = y_int*3), color='gray50', fill=NA, size=.1) +
  
  # soils
  new_scale_fill() + 
  new_scale_color() +
  geom_sf(data = soil %>% rotate_data(y_add = y_int*4), aes(fill = CA_storie), color=NA, show.legend = FALSE) +
  scale_fill_distiller(palette = "BrBG", direction = 1) +
  annotate("text", label='Soil', x=x, y= 69 + y_int*4, hjust = 0, color=color) +
  geom_sf(data = CA %>% rotate_data(y_add = y_int*4), color='gray50', fill=NA, size=.1) +
  
  #ET
  new_scale_fill() + 
  new_scale_color() +
  geom_sf(data = et %>% rotate_data(y_add = y_int*5), aes(fill = X4.2020), color=NA, show.legend = FALSE) +
  scale_fill_distiller(palette = "YlGnBu", direction = 1) +
  annotate("text", label='ET', x=x, y= 69 + y_int*5, hjust = 0, color=color) +
  geom_sf(data = CA %>% rotate_data(y_add = y_int*5), color='gray50', fill=NA, size=.1) +
  
  theme_void() +
  scale_x_continuous(limits = c(-200, -160))

# save plot
ggsave(plot = temp1, filename = here("code", "3_analysis", "1_final", 'map_layers.png'), 
       dpi=200, width = 18, height = 16, units='cm')

