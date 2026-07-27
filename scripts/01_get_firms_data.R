#########################################
### Get FIRMS data                    ###
### Cairngorms Fire                   ###
### Sandra Angers-Blondin             ###
### 27-07-2026                        ###
#########################################


# About -------------------------------------------------------------------

# This script acquires data from FIRMS from the onset of the fire (15 Jul) to now, to initialise the project.

# Another script is responsible for refreshing the data and appending it to the data files periodically (will be scheduled to update twice a day).


# Packages ----------------------------------------------------------------

library(dplyr)
library(sf)
library(httr2)
library(readr)
library(mapview)

source("scripts/helpers.R")


# Parameters --------------------------------------------------------------

MAP_KEY = "ff22c7825ff5ae631a5dcb951953c898"  # request one (free) from NASA FIRMS service

BBOX =  "-4,57.1,-3.5,57.3"   # as west, south, east, north

DAY_RANGE = 5 # days to ask data for; range limited to 1-5, from specified date

DATE_FROM = c("2026-07-14", "2026-07-19", "2026-07-24")

base_url = 'https://firms.modaps.eosdis.nasa.gov/api/area/csv/'

SOURCES = c("VIIRS_NOAA20_NRT", "VIIRS_NOAA21_NRT", "VIIRS_SNPP_NRT")  # product(s) we want


# Send queries --------------------------------------------------------------
# for each date range (as limited to 5 days span) and product (we want all the VIIRS 375m res, near-real-time)

# list to collect results
results <- vector(mode = "list", length = length(SOURCES))
names(results) <- SOURCES

for (s in SOURCES){
  for (d in DATE_FROM){
    
    request <- prep_query(base_url, MAP_KEY, s, BBOX, DAY_RANGE, d) # prepare query
    df <- get_firms(request)  # download data
    
    results[[s]] <- rbind( results[[s]], df) # append results for various dates to the relevant list item
  }
}



# Combine and save --------------------------------------------------------

fires <- do.call(rbind, results) # combine all

saveRDS(fires, "data_raw/firms_master.RDS")


