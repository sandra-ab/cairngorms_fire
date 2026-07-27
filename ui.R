#########################################
### Cairngorms Fire Explorer - UI     ###
### Sandra Angers-Blondin             ###
### 26-07-2026                        ###
#########################################

ui <- page_sidebar(
   title = "Cairngorms Fire Explorer",

  ### Setup and theming -------------------------------------
  
   ## Dynamic restyling of map using JS
   tags$script(HTML("
Shiny.addCustomMessageHandler('restyle', function(x) {
  var map = HTMLWidgets.find('#mymap').getMap();
  
  map.eachLayer(function(layer) {
    if(layer.options && layer.options.layerId) {

      var id = layer.options.layerId;

      if(x.colours[id] !== undefined) {
        layer.setStyle({
          fillColor: x.colours[id]
        });
      }
    }
  });
});
")), 
  
   # Theming
   theme = 
     bs_theme(
       bootswatch = "lux", version = 5,
       primary = "#f6b338",
       secondary = "#545454",
       "navbar-bg" = "#000",
       "nav-link-color" = "#FC0 !important",
       "nav-link-font-size" = "25px",
       "nav-link-font-weight" = "normal",
       "nav-text-color" = "#fc0 !important",
       "nav-link-hover-color" = "#fc0 !important",
       base_font = font_google("Source Sans 3"),
       heading_font = font_google("Oswald")
     ),
   
   ## Extra theming (CSS)
   tags$style(HTML("
   .warning {
      color: #2f636e;
   }
  .slider-animate-button { font-size: 30pt !important; }
   ")),


# Side bar ----------------------------------------------------------------

  sidebar = sidebar(
    width = "30%", open =TRUE,
  
   # ABOUT ---------------------------------------
    accordion(open = TRUE, 
              
      accordion_panel(
        title = "About", 
        includeHTML("www/about.html"),
        includeHTML("www/latest.html")
        ))
    ,
    
    radioButtons(
      "view_mode",
      "Map mode",
      choices = c(
        "Fire timeline" = "timeline",
        "Affected area" = "footprint"
      )
    ),
    
   # TIMELINE MODE ---------------------------------

    conditionalPanel(
      "input.view_mode == 'timeline'",
      
      p("Select a day using the slider, or press play to view the evolution of the fire. The activity for the day will display according to the fire radiative power, and earlier days will appear in grey."
        , class="warning"),
      
     # textOutput("selected_date"),
      
          sliderInput("day", "Select day",
                min = 1,
                max = TODAY,
                value = 1,
                step = 1,
                #timeFormat="%d-%m",
                animate = animationOptions(interval = 1500,
                                           loop = FALSE))
    ),
    
    ### SUMMARY MAP --------------------------------
   
    conditionalPanel(
      "input.view_mode == 'footprint'",
      
      p("This shows the full extent of the fire zone. This does NOT all represent burned areas. They are places where at least one fire event was detected within the satellite pixel (375m), but some ground may be intact."
        , class="warning"),
      
      radioButtons(
        "symbology",
        "Style map by:",
        choices = c(
          "Fire radiative power" = "frp",
          "Days since detection" = "timesince",
          "Detection confidence" = "conf"
        ))
      
      # select layers to overlay
      # stats of habitats?

   ),
   
   
   
   ### Footer --------------------------------------
  p(actionLink('link_disclaim', 'Disclaimer')),
  p("Developed by Sandra Angers-Blondin, July 2026")

  ),
  

# Main panel (Map) --------------------------------------------------------
  card(
    #card_header("Histogram"),
    full_screen = TRUE,
    leafletOutput("mymap", width = "100%", height = "90vh")
  )

  # conditionalPanel(
  #   "input.view_mode == 'timeline'",
  #   absolutePanel(
  #     top = 10,
  #     left = "50%",
  #     style = "
  #   transform: translateX(-50%);
  #   background: rgba(255,255,255,0.9);
  #   padding: 8px 15px;
  #   border-radius: 4px;
  #   font-weight: bold;
  #   text-align: center;
  #   z-index: 1000;
  # ",
  #     textOutput("current_date")
  #   )
  # )
)

