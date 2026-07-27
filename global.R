#########################################
### Cairngorms Fire Explorer - global ###
### Sandra Angers-Blondin             ###
### 26-07-2026                        ###
#########################################


# Packages ----------------------------------------------------------------

library(shiny)
library(bslib)
library(dplyr)
library(sf)
library(leaflet)
library(tidyr)
library(shinyWidgets)


# Global data -------------------------------------------------------------

# The 100-m grid we use to show areas on map
cells <- readRDS("data/fire_cells.RDS")

# Fire data, summarised daily, for activity
fires <- readRDS("data/fire_daily.RDS") 

# Fire data summary for full period 
fire_summary <- readRDS("data/fire_summary.RDS")



# Date handing ------------------------------------------------------------

# numeric code for today (actually, latest day)
TODAY <- as.numeric(as.numeric(max(fire_summary$last) - as.Date("2026-07-15")) + 1)


# date to day lookup
dates <- setNames(
  as.Date(c(as.Date("2026-07-15"):(as.Date("2026-07-15")+TODAY-1))),
  c(1:TODAY)
)


# Map setup ---------------------------------------------------------------

bgmap <- leaflet(options = leafletOptions(minZoom = 7, maxZoom = 16)) %>% 
  setView(-3.6, 57.18, zoom = 12) %>%  # sensible starting point
  setMaxBounds(-6, 46, 3, 61) %>% # stop user from panning across the world
  addProviderTiles("Esri.WorldTopoMap", group = "=Topography") %>% 
  addProviderTiles("Esri.WorldImagery", group = "Satellite") %>% 
  addProviderTiles("CartoDB.Positron", group = "Minimal") %>% 
  addLayersControl(baseGroups = c("Topography", "Satellite", "Minimal"),   
                   options = layersControlOptions(collapsed = FALSE))


# Palettes ----------------------------------------------------------------

styles <- list(
  
  # Fire radiative power: must start at 0 (older days) and max is the max value in data
  "frp" = list(
    variable = "frp",
    palette = colorNumeric("plasma", 
                       domain = c(0, max(fires[names(fires)[grepl("day_", names(fires))]], na.rm=T)),  
                       na.color = "transparent")
    ),
  
  # Time since burn 
  "timesince" = list(
    variable = "timesince",
    palette = colorNumeric("cividis", 
                             domain = c(min(fire_summary$timesince,na.rm=T), max(fire_summary$timesince,na.rm=T)),
                             reverse = TRUE)
    ),
  
  # Confidence
  "conf" = list(
    variable = "conf",
    palette = colorFactor("viridis", 
                       levels = levels(fire_summary$conf))
  )
  
)

# a wrapper function to turn 0 values (burned in earlier days) to grey
timeline_pal <- function(x) {
  cols <- styles$frp$palette(x)
  cols[x == 0 & !is.na(x)] <- "#98886e"
  cols
}


# Legends
legends <- c(
  "frp" = "Fire radiative power (MW)",
  "timesince" = "Days since first detection",
  "conf" = "Confidence"
)


# Make data spatial -------------------------------------------------------

fires <- right_join(cells, fires)
firefoot <- right_join(cells, fire_summary)

rm(fire_summary)