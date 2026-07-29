#########################################
### AUTOMATED data refresh            ###
### Cairngorms Fire                   ###
### Sandra Angers-Blondin             ###
### 29-07-2026                        ###
#########################################

# About -------------------------------------------------------------------

# This is a wrapper around scripts:
# 02_update_firms_data
# 03_clean_firms_data

# which can be set to run periodically using Windows Task Scheduler. New data will be grabbed from FIRMS, tidied up, and pushed to GitHub.

## custom function to write log
add_to_log <- function(...) {
  cat(
    format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    ...,
    "\n",
    file = "logs/update.log",
    append = TRUE
  )
}

add_to_log("Starting")

source("scripts/02_update_firms_data.R")

log_records <- nrow(fires) - nrow(archive)
add_to_log(paste0("Added ", log_records, " records."))

source("scripts/03_clean_firms_data.R")

add_to_log("Update successful")