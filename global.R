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
library(plotly)
library(shinymanager)

# Global data -------------------------------------------------------------

## Load all data the app needs
#load("app-data/fire_data.RData") # TODO load from Github instead

load(url(
  "https://raw.githubusercontent.com/sandra-ab/cairngorms_fire/main/app-data/fire_data.RData"
))


# Date handing ------------------------------------------------------------

# numeric code for today (actually, latest day)
TODAY <- as.numeric(as.numeric(max(fire_summary$last) - as.Date("2026-07-15")) + 1)


# date to day lookup
dates <- setNames(
  as.Date(c(as.Date("2026-07-15"):(as.Date("2026-07-15")+TODAY-1))),
  c(1:TODAY)
)

# update days since detection
fire_summary$timesince <- as.numeric(Sys.Date() - fire_summary$last)

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

## max frp from daily data
FRPmax <- max(fires[names(fires)[grepl("day_", names(fires))]], na.rm=T)

styles <- list(
  
  # Fire radiative power: must start at 0 (older days) and max is the max value in data
  "frp" = list(
    variable = "frp",
    palette = colorNumeric("plasma", 
                       domain = c(0, FRPmax),  
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



# Simplify habitats -------------------------------------------------------

# group everything with less than 0.1 km2 together

hab_areas <- hab_areas %>% 
  mutate(habitat = case_when(
    area_km2 < 0.1 ~ "Other",
    TRUE ~ habitat
  )) %>% 
  group_by(habitat) %>% 
  summarise(area_km2 = sum(area_km2, na.rm=T))

hab_areas$habitat <- factor(hab_areas$habitat, levels = hab_areas$habitat[order(hab_areas$area_km2)], ordered=T)

# Draw sparkline ----------------------------------------------------------

# spark <- ggplot(area,
#                 aes(x=day, y=area_km2, group = 1
#                     ,text = paste0("Area: ", round(area_km2,1), " km²")
#                     )) +
#   geom_line() +
#   #geom_point(size=2, alpha=0) +    # invisible hover targets
#   theme_void()
# 
# spark <- ggplotly(spark,
#                   height=50,
#                   tooltip = c("text")) %>%
#   layout(
#     margin = list(l = 0, r = 0, t = 0, b = 0),
#     # yaxis = list(
#     #   visible = FALSE,
#     #   fixedrange = TRUE,
#     #   range = c(0, max(area$area_km2, na.rm=T))
#     # ),
#     paper_bgcolor = "rgba(0,0,0,0)",
#     plot_bgcolor  = "rgba(0,0,0,0)") %>%
#   config(
#     displayModeBar = FALSE
#   )


