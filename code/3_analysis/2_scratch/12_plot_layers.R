# This is code adapted from https://www.urbandemographics.org/post/figures-map-layers-r/
# and is used to map the different layers of data used in my project

# Anna Boser Nov 8, 2021

library(easypackages)
easypackages::packages("sf",
                       "raster",
                       "stars",
                       "r5r",
                       "geobr",
                       "aopdata",
                       "gtfs2gps",
                       "ggplot2",
                       "osmdata",
                       "h3jsr",
                       "viridisLite",
                       "ggnewscale",
                       "dplyr",
                       "magrittr",
                       prompt = FALSE
)

# Functions to tilt sf
# Original function created by Stefan Jünger.

rotate_data <- function(data, x_add = 0, y_add = 0) {
  
  shear_matrix <- function(){ matrix(c(2, 1.2, 0, 1), 2, 2) }
  
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



### plot  ----------------

# parameters for the annotation
x = -141.25 
color = 'gray40'

temp1 <- ggplot() +
  
  # terrain
  geom_sf(data = dem %>% rotate_data(), aes(fill=poa_elevation.tif), color=NA, show.legend = FALSE) +
  scale_fill_distiller(palette = "YlOrRd", direction = 1) +
  annotate("text", label='Terrain', x=x, y= -8.0, hjust = 0, color=color) +
  # labs(caption = "image by @UrbanDemog")

temp2 <- temp1 +
  
  # pop income
  new_scale_fill() + 
  new_scale_color() +
  geom_sf(data = subset(landuse,P001>0) %>% rotate_data(y_add = .1), aes(fill=R001), color=NA, show.legend = FALSE) +
  scale_fill_viridis_c(option = 'E') +
  annotate("text", label='Population', x=x, y= -7.9, hjust = 0, color=color) +
  
  # schools
  geom_sf(data = hex %>% rotate_data(y_add = .2), color='gray50', fill=NA, size=.1) +
  geom_sf(data = schools %>% rotate_data(y_add = .2), color='#0f3c53', size=.1, alpha=.8) +
  annotate("text", label='Schools', x=x, y= -7.8, hjust = 0, color=color) +
  
  # hospitals
  geom_sf(data = hex %>% rotate_data(y_add = .3), color='gray50', fill=NA, size=.1) +
  geom_sf(data = hospitals %>% rotate_data(y_add = .3), color='#d5303e', size=.1, alpha=.5) +
  annotate("text", label='Hospitals', x=x, y= -7.7, hjust = 0, color=color) +
  
  # OSM
  geom_sf(data = roads2 %>% rotate_data(y_add = .4), color='#019a98', size=.2) +
  annotate("text", label='Roads', x=x, y= -7.6, hjust = 0, color=color) +
  
  # public transport
  geom_sf(data = gtfs %>% rotate_data(y_add = .5), color='#0f3c53', size=.2) +
  annotate("text", label='Public transport', x=x, y= -7.5, hjust = 0, color=color) +
  
  # accessibility
  new_scale_fill() + 
  new_scale_color() +
  geom_sf(data = subset(landuse, P001>0) %>% rotate_data(y_add = .6), aes(fill=CMATT30), color=NA, show.legend = FALSE) +
  scale_fill_viridis_c(direction = 1, option = 'viridis' ) +
  theme(legend.position = "none") +
  annotate("text", label='Accessibility', x=x, y= -7.4, hjust = 0, color=color) +
  theme_void() +
  scale_x_continuous(limits = c(-141.65, -141.1))


# save plot
ggsave(plot = temp2, filename = 'map_layers.png', 
       dpi=200, width = 15, height = 16, units='cm')


