#########################################
### Cairngorms Fire Explorer - UI     ###
### Sandra Angers-Blondin             ###
### 26-07-2026                        ###
#########################################

ui <- secure_app(
  page_fillable(
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
"),
  ## add tooltip functionality for html pages             
  HTML("
document.addEventListener('DOMContentLoaded', function() {
var tooltipTriggerList = [].slice.call(
document.querySelectorAll('[data-bs-toggle=\"tooltip\"]')
);
tooltipTriggerList.map(function (tooltipTriggerEl) {
return new bootstrap.Tooltip(tooltipTriggerEl);
});
});
")
               
               
  ), 
  
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
  
  .tooltip-inner {
  background-color: #f6b338;
  }
  
  .tooltiptext {
  text-decoration:underline;
  text-decoration-color: #f6b338;
  }
  
  .accordion-button.collapsed {
  background-color:#f6b338;
  }

   ")),

# ABOUT ---------------------------------------
    accordion(open = FALSE, 
              
      accordion_panel(
        title = "About", 
        includeHTML("www/about.html"),
        p("Last updated: ", LATEST)
          #includeHTML("www/latest.html")
        ))
    ,
      
# Main panel (Map) --------------------------------------------------------
#card(
  #full_screen = TRUE,
  leafletOutput("mymap", width = "100%", height = "90vh"),
#)  

# Control panel ----------------------------------------------------------------

absolutePanel(
  width = "300px", 
  left = "3%", 
  top = "25%", 
  draggable=TRUE,
  class = "bg-light p-3 rounded",

  tags$details( # to collapse
    open = TRUE,
    tags$summary(  span("Controls", style = "font-size:1.4em;"),
                   span(
                     icon("grip"),
                     style = "float:right; opacity:0.6;"
                   )),
    br(),
    
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
      
      tags$details(
        class = "mt-2 mb-3",
        tags$summary(
          " What am I seeing?",
          style = "color:#f6b338;"
        ),
        p("Select a day using the slider, or press play to view the evolution of the fire. The activity for the day will display, with earlier days greyed out. NB: Some days have no activity: satellite observations are sensitive to cloud cover and smoke, overpass timing, and the intensity of the fire."
          , class="warning")
      ),
      
      # # sparkline just above the slider
      # plotlyOutput("sparkline", height = "50px"),
      

      # slider (day selector)
          sliderInput("day", "Select day",
                min = 1,
                max = as.integer(names(dates)[which(dates == LATEST)]),
                value = 1,
                step = 1,
                #timeFormat="%d-%m",
                animate = animationOptions(interval = 1500,
                                           loop = FALSE))
    ),
    
    ### SUMMARY MAP --------------------------------
   
    conditionalPanel(
      "input.view_mode == 'footprint'",
      
      tags$details(
        class = "mt-2 mb-3",
        tags$summary(
          " What am I seeing?",
          style = "color:#f6b338;"
        ),
        p("This shows the full extent of the fire zone. This does NOT all represent burned areas. They are places where at least one fire event was detected within the satellite pixel (375m), but some ground may be intact."
          , class="warning")
      ),

      
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
  ) # end details
    ), # end absolute panel
   
   ### Footer --------------------------------------
  p(actionLink('link_disclaim', 'Disclaimer')),
  p("Developed by Sandra Angers-Blondin, July 2026")

 
  
)

) # end secure app