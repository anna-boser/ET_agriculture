################################################################################
# This script loads in data dictionaries from 
# https://www.nass.usda.gov/Research_and_Science/Cropland/metadata/2020_cultivated_layer_metadata.htm
# and formats and groups them for my analyses

# Anna Boser June 28 2019
################################################################################

# Note to self: There was some mixing up because the actual CDL uses the label "Grass/Pasture" 
# while the original dictionary had "Grassland/Pasture". I changed it to "Grass/Pasture" on July 12
# but there may be problems with earlier code which used "Grassland/Pasture"

# additionally, classes 37, 59, 60 used to be listed as uncultivated but I changed that since this is clearly a mistake 
# (see https://www.nass.usda.gov/Research_and_Science/Cropland/metadata/metadata_ca18.htm -- they're listed under crops)

library(here)

# code dictionary to know land cover from CDL
code_dictionary_crops <- read.csv(here("data", 
                                       "raw", 
                                       "CDL", 
                                       "code_dictionary_crops"), 
                                  sep = ",", 
                                  col.names = c("code", "class"), 
                                  header = FALSE)
code_dictionary_crops$cultivated <- "Cultivated"

code_dictionary_noncrops <- read.csv(here("data", 
                                          "raw", 
                                          "CDL", 
                                          "code_dictionary_noncrop"), 
                                     sep = ",", 
                                     col.names = c("code", "class"), 
                                     header = FALSE)
code_dictionary_noncrops$cultivated <- "Uncultivated"
code_dictionary <- rbind(code_dictionary_crops, code_dictionary_noncrops)

# remove space at the beginning of strings and replace . with space
code_dictionary$class <- gsub("[.]", " ", code_dictionary$class)

# hand make bigger classes for easier visualization
# categories adapted from http://www.fao.org/3/x0490e/x0490e0b.htm#tabulated%20kc%20values
group_dictionary <- c("Corn"   =  "Cereals", 
                      "Cotton" =    "Fibre Crops", 
                      "Rice"     =     "Cereals",
                      "Sorghum" =  "Cereals",     
                      "Soybeans" = "Legumes",   
                      "Sunflower" =  "Oil Crops",
                      "Peanuts"  = "Legumes",                      
                      "Tobacco" = "Other", 
                      "Sweet Corn" =  "Cereals", 
                      "Pop or Orn Corn" =  "Cereals", 
                      "Mint"  = "Vegetables",
                      "Barley" = "Cereals", 
                      "Durum Wheat"  = "Cereals", 
                      "Spring Wheat" = "Cereals", 
                      "Winter Wheat" ="Cereals", 
                      "Other Small Grains"= "Cereals",   
                      "Dbl Crop WinWht/Soybeans" = "Other", 
                      "Rye" = "Forages", 
                      "Oats" = "Cereals", 
                      "Millet"  = "Cereals", 
                      "Speltz" = "Cereals", 
                      "Canola" = "Oil Crops",
                      "Flaxseed"   = "Oil Crops",
                      "Safflower"  = "Oil Crops",
                      "Rape Seed"  = "Oil Crops",
                      "Mustard" = "Other", 
                      "Alfalfa" = "Forages", 
                      "Camelina"  = "Oil Crops",                   
                      "Buckwheat"  =  "Cereals", 
                      "Sugarbeets" = "Roots and Tubers", 
                      "Dry Beans" = "Legumes", 
                      "Potatoes"  = "Roots and Tubers", 
                      "Other Crops" = "Other", 
                      "Sugarcane" = "Sugarcane", 
                      "Sweet Potatoes"= "Roots and Tubers", 
                      "Misc Vegs & Fruits" = "Vegetables", 
                      "Watermelons" = "Vegetables", 
                      "Onions" = "Vegetables",  
                      "Cucumbers" = "Vegetables",
                      "Chick Peas" = "Legumes", 
                      "Lentils" = "Legumes", 
                      "Peas"= "Legumes", 
                      "Tomatoes"  = "Vegetables", 
                      "Caneberries" = "Grapes and Berries", 
                      "Hops" = "Grapes and Berries", 
                      "Herbs" = "Other", 
                      "Clover/Wildflowers" = "Forages", 
                      "Fallow/Idle Cropland" = "Fallow/Idle", 
                      "Cherries" = "Fruit/Nut Trees", 
                      "Peaches" = "Fruit/Nut Trees", 
                      "Apples"  = "Fruit/Nut Trees", 
                      "Grapes" = "Grapes and Berries", 
                      "Christmas Trees" = "Other", 
                      "Other Tree Crops" = "Other", 
                      "Citrus" = "Fruit/Nut Trees", 
                      "Pecans"  = "Fruit/Nut Trees", 
                      "Almonds" = "Fruit/Nut Trees", 
                      "Walnuts" = "Fruit/Nut Trees", 
                      "Pears"  = "Fruit/Nut Trees", 
                      "Pistachios"  = "Fruit/Nut Trees", 
                      "Triticale" =  "Cereals", 
                      "Carrots"  = "Vegetables", 
                      "Asparagus" = "Vegetables", 
                      "Garlic" = "Vegetables", 
                      "Cantaloupes" = "Vegetables", 
                      "Prunes" = "Fruit/Nut Trees", 
                      "Olives" = "Fruit/Nut Trees", 
                      "Oranges" = "Fruit/Nut Trees", 
                      "Honeydew Melons"  = "Vegetables", 
                      "Broccoli" = "Vegetables", 
                      "Avocado" = "Fruit/Nut Trees", 
                      "Peppers"   = "Vegetables", 
                      "Pomegranates"  = "Fruit/Nut Trees", 
                      "Nectarines"  = "Fruit/Nut Trees", 
                      "Greens" = "Vegetables",
                      "Plums"= "Fruit/Nut Trees", 
                      "Strawberries"  = "Vegetables",
                      "Squash"  = "Vegetables",
                      "Apricots"= "Fruit/Nut Trees", 
                      "Vetch" = "Legumes", 
                      "Dbl Crop WinWht/Corn" = "Cereals", 
                      "Dbl Crop Oats/Corn" = "Cereals", 
                      "Lettuce" = "Vegetables",
                      "Dbl Crop Triticale/Corn" = "Cereals", 
                      "Pumpkins"= "Vegetables",
                      "Dbl Crop Lettuce/Durum Wht" = "Other", 
                      "Dbl Crop Lettuce/Cantaloupe" =  "Vegetables",
                      "Dbl Crop Lettuce/Cotton" = "Other", 
                      "Dbl Crop Lettuce/Barley" = "Other", 
                      "Dbl Crop Durum Wht/Sorghum" = "Cereals", 
                      "Dbl Crop Barley/Sorghum" = "Cereals", 
                      "Dbl Crop WinWht/Sorghum" = "Cereals", 
                      "Dbl Crop Barley/Corn"  = "Cereals", 
                      "Dbl Crop WinWht/Cotton"  = "Cereals", 
                      "Dbl Crop Soybeans/Cotton" = "Cereals", 
                      "Dbl Crop Soybeans/Oats" = "Cereals", 
                      "Dbl Crop Corn/Soybeans" = "Cereals", 
                      "Blueberries" = "Grapes and Berries", 
                      "Cabbage" =  "Vegetables",
                      "Cauliflower" =  "Vegetables",
                      "Celery"  =  "Vegetables",
                      "Radishes" = "Roots and Tubers", 
                      "Turnips" = "Roots and Tubers", 
                      "Eggplants"  =  "Vegetables",
                      "Gourds"  =  "Vegetables",
                      "Cranberries" = "Grapes and Berries",
                      "Dbl Crop Barley/Soybeans" = "Cereals", 
                      "Other Hay/Non Alfalfa" = "Uncultivated field", 
                      "Sod/Grass Seed"  = "Uncultivated field", 
                      "Switchgrass"  = "Uncultivated field", 
                      "Forest"  = "Forest", 
                      "Shrubland"  = "Uncultivated field",                 
                      "Barren" = "Barren",
                      "Clouds/No Data"  = "Other uncultivated", 
                      "Developed" = "Developed", 
                      "Water"  = "Water", 
                      "Wetlands"  = "Wetlands", 
                      "Nonag/Undefined" ,
                      "Aquaculture" = "Aquaculture",            
                      "Open Water"= "Water", 
                      "Perennial Ice/Snow" = "Other uncultivated", 
                      "Developed/Open Space" = "Developed", 
                      "Developed/Low Intensity"= "Developed", 
                      "Developed/Med Intensity"= "Developed", 
                      "Developed/High Intensity" = "Developed", 
                      "Barren" =  "Barren",                   
                      "Deciduous Forest"   = "Forest", 
                      "Evergreen Forest"  = "Forest", 
                      "Mixed Forest"   = "Forest", 
                      "Shrubland"  = "Uncultivated field", 
                      "Grass/Pasture"  = "Grassland/Pasture",
                      "Woody Wetlands" = "Wetlands", 
                      "Herbaceous Wetlands" = "Wetlands")


code_dictionary$group <- group_dictionary[as.character(code_dictionary$class)]

code_dictionary$double_crop <- grepl("Dbl Crop", code_dictionary$class, fixed = TRUE)

code_dictionary$counterfactual <- ifelse(code_dictionary$class %in% c("Grass/Pasture", "Shrubland", "Barren"), 1, 0)

write.csv(code_dictionary, 
          file = here("data", 
                      "intermediate", 
                      "CDL_code_dictionary.csv"), 
          row.names = FALSE)
