#########################################
### Helper function: get habitats     ###
### Cairngorms Fire                   ###
### Sandra Angers-Blondin             ###
### 27-07-2026                        ###
#########################################

# About -------------------------------------------------------------------

# This is a helper function that extracts land cover data from the fire area, calculates area affected and returns a dataframe of km2 by habitat

#' Calculate affected habitat areas in fire footprint
#' 
#' Uses the Scotland Land Cover Map (2024) and returns a dataframe of habitat area in the fire footprint.
#' @param x fire footprint, as an sf object
#' @param lc path to the Land Cover raster

calculate_habitats <- function(x, lc){
  
  lc <- terra::rast(lc) %>% 
    terra::crop(x) %>% terra::mask(x)
  
  df <- terra::freq(lc) %>% 
    dplyr::rename(habcode = value) %>% 
    dplyr::mutate(area_km2 = count*terra::res(lc)[[1]]^2/1e6)
  
  # join habitat desc to names
  habs <- dplyr::tribble(
    ~habcode, ~habitat,
    "P",  "Water",
    "Q1", "Raised / blanket bogs",
    "Q2", "Valley mires, poor fens, transition mires",
    "Q4", "Base-rich fens and calcareous spring mires",
    "R1", "Dry grasslands",
    "R2", "Mesic grasslands",
    "R3", "Wet grasslands",
    "R4", "Alpine and subalpine grasslands",
    "R5", "Forest fringes and clearings, tall forb stands",
    "S2", "Arctic, alpine and subalpine scrub",
    "S3", "Temperate scrub",
    "S4", "Temperate shrub heathland",
    "S9", "Riverine and fen scrubs",
    "T1", "Deciduous broadleaved forest",
    "T3M", "Non-native plantation forest",
    "T3N", "Native plantation forest",
    "T351", "Caledonian pine forest",
    "T4", "Lines of trees or small/felled/young forest",
    "U2", "Screes",
    "U3", "Inland cliffs, rock pavements and outcrops",
    "V1", "Arable land",
    "J", "Built-up",
    "OW", "Windthrow",
    "MA4", "Littoral sediment",
    "N1", "Coastal dunes and sandy shores",
    "N2", "Coastal shingle",
    "N3", "Rock cliffs, ledges and shores",
    "V15", "Bare tilled, fallow or abandoned arable land"
  )
  
  df <- left_join(df, habs)
  return(list(map = lc, areas = df))
  
}
