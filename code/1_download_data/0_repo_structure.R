################################################################################
# This script sets up the basic data repository structure 
# to begin filling in with data

# Anna Boser Sep 9 2021
################################################################################

library(here)

dir.create(here("data"))

dir.create(here("data", "raw"))
dir.create(here("data", "intermediate"))
dir.create(here("data", "for_analysis"))