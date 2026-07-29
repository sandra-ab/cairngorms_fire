#########################################
### Clean FIRMS data                  ###
### Cairngorms Fire                   ###
### Sandra Angers-Blondin             ###
### 27-07-2026                        ###
#########################################

# About -------------------------------------------------------------------

# This script takes all the FIRMS observations and cleans up the file:
# - remove any possible duplicates from inaccurate queries
# - buffers the points and extract the data into a grid
# - create the files for the app


# Packages ----------------------------------------------------------------

library(dplyr)
library(sf)
library(mapview)
library(tidyr)
library(gert)  # for git updates

# Parameters --------------------------------------------------------------

BUFFER = 375/2  # a VIIRS pixel is around 375m; we'll buffer (circles) by half that amount to create the "coverage" zone for an observation and transfer into our finer grid

GRIDSIZE = 100 # 100m for slightly nicer contours 
COVER_THRESHOLD = 0.5 # % cover the FIRMS observation must have in the grid cell to retain it as part of the footprint


# Load data ---------------------------------------------------------------

# wider area of interest for this fire event (I created it in QGIS)
aoi <- st_read("data_raw/fire_AOI.gpkg")

# the FIRMS data
fires <- readRDS("data_raw/firms_master.RDS")


LATEST <- max(fires$acq_date) # latest available data

# Clean up FIRMS ---------------------------------------------------------

# keep relevant attributes
fires <- fires %>% 
  select(lat = latitude, lon = longitude, 
         date = acq_date, time = acq_time, 
         satellite, confidence,   # product and confidence level
         frp,                     # fire radiative power
         daynight)                # for QA only (night detection is easier as greater thermal contrast)

# Convert to sf points, reproject to BNG, buffer to roughly the area they capture
fires <- st_as_sf(fires, coords = c("lon","lat"), crs = 4326) %>% 
  st_transform(27700) %>% 
  st_buffer(BUFFER)

#mapview(fires, zcol="frp")



# Create grid for area -----------------------------------------------

aoi_grid <- st_make_grid(aoi, cellsize = GRIDSIZE) %>% st_as_sf()

#mapview(aoi_grid)

# We will extract results into this grid to create our fire "footprints"
aoi_grid$pixID <- c(1:nrow(aoi_grid)) # unique ID to associate observations to pixels

# Extract data ------------------------------------------------------------

# "transfer" observations by intersecting. We can drop the geoms as we'll just need to join the info to the pixel ID whenever needed
fires <- st_intersection(fires, aoi_grid) %>% 
  mutate(frac_cover = as.numeric(st_area(.))/GRIDSIZE^2) %>% 
  filter(frac_cover >= COVER_THRESHOLD) %>% 
  st_drop_geometry()

# turn low-nominal-high to 1-2-3 for a confidence score
fires$confidence <- factor(fires$confidence, levels = c("l", "n", "h"), labels = c(1,2,3), ordered = T) %>% as.numeric()


# Daily summaries ---------------------------------------------------------

# Summarise by grid cell by day
fires_day <- fires %>% 
  group_by(pixID, date) %>% 
  summarise(frp = max(frp, na.rm=T), 
            conf = round(median(confidence,0)), 
            .groups="drop")


# Create explicit days even when missing data
fires_day <- fires_day %>% 
  mutate(day = as.numeric(date - as.Date("2026-07-15")) + 1) %>% # fire starts on day 1 (15th Jul)
  select(-conf, -date) %>% 
  complete(pixID, day = 1:(LATEST - as.Date("2026-07-15") + 1)) # add missing days (all days for all pixels)

# Compute the area affected before continuing the data cleaning
area <- fires_day %>% 
  group_by(day) %>% 
  summarise(npix = sum(!is.na(frp)), .groups="drop") %>% 
  mutate(area_km2 = npix*GRIDSIZE^2 / 1e6) %>% select(-npix)


# Recode missing to 0 when there was a detection in that pixel earlier (will be used to symbolise "older" burns)
fires_day <- fires_day %>% 
  arrange(pixID, day) %>%
  group_by(pixID) %>%
  mutate(
    frp = if_else(
      is.na(frp) & cumany(!is.na(frp)),  # replace NAs with 0 if we've had observations before
      0,
      frp
    )
  ) %>%
  ungroup() %>% 
  pivot_wider(names_from = day, values_from = frp, names_prefix = "day_")

# ready for app


# Overall summary ---------------------------------------------------------

# And create full footprint (summary) version
fires_footprint <- fires %>% 
  group_by(pixID) %>% 
  summarise(frp = max(frp, na.rm=T), 
            conf = round(median(confidence,0)), 
            first = min(date),
            last = max(date),
            .groups="drop")

# number of days between first and last detection
fires_footprint$duration = as.numeric(fires_footprint$last - fires_footprint$first) + 1
fires_footprint$is_current <- fires_footprint$last == max(fires_footprint$last)
fires_footprint$timesince <- as.numeric(Sys.Date() - fires_footprint$last)

# confidence back to factor
fires_footprint$conf <- factor(fires_footprint$conf, levels = c(1,2,3), labels = c("Low", "Nominal", "High"), ordered=T)


# # how to see activity for a given day
# mapview(right_join(aoi_grid, filter(fires_day, date == "2026-07-15")), zcol="frp")
# 
# # full footprint
# mapview(right_join(aoi_grid, fires_footprint), zcol = "is_current")


# Save all data ---------------------------------------------------------------

# # for now, saved in app; will need to be pushed to git and read from there
# saveRDS(aoi_grid %>% st_transform(4326), "data/fire_cells.RDS")
# saveRDS(fires_footprint, "data/fire_summary.RDS")
# saveRDS(fires_day, "data/fire_daily.RDS")
# saveRDS(area, "data/area_spark.RDS")
# 
# # Save a very small metadata HTML
# writeLines(
#   paste0("<p><strong> Last update: </strong>", LATEST ,"</p>"),
#   "www/latest.html"
# )



# Push all data to GitHub -------------------------------------------------

cells <- aoi_grid %>% st_transform(4326)
fires <- fires_day
fire_summary <- fires_footprint


## Save to a folder that the app will read from, can load ALL data in one go
save(cells, fires, fire_summary, area, LATEST,
     file = "app-data/fire_data.RData") 

# saveRDS(list(
#   cells = cells, 
#   fires = fires, 
#   fire_summary = fire_summary, 
#   area = area, 
#   LATEST = LATEST),
#      file = "app-data/fire_data.RDS")

if (nrow(gert::git_status()) > 0){
if ("app-data/fire_data.RData" %in% gert::git_status()$file) {
  
  git_add("app-data/fire_data.RData")  # add the file we want to update
  git_commit(paste0("Automated data update ", format(Sys.time(), "%Y %m %d %X")))
  git_push()

}}

