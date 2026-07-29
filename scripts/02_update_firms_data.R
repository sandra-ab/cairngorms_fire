#########################################
### Update FIRMS data                 ###
### Cairngorms Fire                   ###
### Sandra Angers-Blondin             ###
### 27-07-2026                        ###
#########################################


# About -------------------------------------------------------------------

# This script refreshes the FIRMS data periodically.


# Packages ----------------------------------------------------------------

library(dplyr)
library(sf)
library(httr2)
library(readr)
library(mapview)

source("scripts/helpers.R")

# Parameters --------------------------------------------------------------

MAP_KEY = Sys.getenv("FIRMS_MAP_KEY") # request one (free) from NASA FIRMS service

BBOX =  "-4,57.1,-3.5,57.3"   # as west, south, east, north

DAY_RANGE = 5 # days to ask data for; range limited to 1-5, from specified date. Script will be scheduled to update daily but leaving it at 5 to make sure we capture everything

base_url = 'https://firms.modaps.eosdis.nasa.gov/api/area/csv/'

SOURCES = c("VIIRS_NOAA20_NRT", "VIIRS_NOAA21_NRT", "VIIRS_SNPP_NRT")  # product(s) we want

# Identify latest observations --------------------------------------------

archive <- readRDS("data_raw/firms_master.RDS")
LATEST_DAY <- max(archive$acq_date)

# Send queries --------------------------------------------------------------

# for each product (we want all the VIIRS 375m res, near-real-time), request data from the last day in our previous file

# list to collect results
results <- vector(mode = "list", length = length(SOURCES))
names(results) <- SOURCES

for (s in SOURCES){
    
    request <- prep_query(base_url, MAP_KEY, s, BBOX, DAY_RANGE, LATEST_DAY) # prepare query
    df <- get_firms(request)  # download data
    
    results[[s]] <- rbind( results[[s]], df) # append results for various dates to the relevant list item

}



# Append results ----------------------------------------------------------

fires <- do.call(rbind, results) # combine new results

fires <- rbind(archive, fires)  # append to previous

fires <- fires %>% distinct()  # remove duplicate observations (overlaps in requests)


saveRDS(fires, "data_raw/firms_master.RDS")


