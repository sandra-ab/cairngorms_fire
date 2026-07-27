#########################################
### Cairngorms Fire Explorer - server ###
### Sandra Angers-Blondin             ###
### 26-07-2026                        ###
#########################################

## TODO
# bring in javascript symbology to update fill by switching symbology attribute
# cast daily data to have columns day1, day2, day3 ....
# tie to slider 


function(input, output, session) {

  ## Initialise map
  output$mymap <- renderLeaflet({
    bgmap 
  }) 
  
# Tracking / debugging ----------------------------------------------------------

# observe({
#   print(input$day)
# })


# Map updates -------------------------------------------------------------

  observe({
    
    if (input$view_mode == "timeline") {

      leafletProxy("mymap", data = fires) %>%
        clearShapes() %>% 
        #clearControls() %>%
        #removeControl("date") %>%
        # addControl(
        #   html = sprintf(
        #     "<div style='font-weight:bold;background:white;
        #             padding:6px;border-radius:4px'>
        #    %s
        #  </div>",
        #     unlist(dates[[isolate(input$day)]])
        #   ),
        #   position = "topright",
        #   layerId = "date"
        # ) %>%
        
        addPolygons(data = fires,
                      layerId = ~pixID,
                      group = "fire_day",
                      fillColor = ~styles$frp$palette(fires[[paste0("day_", isolate(input$day))]]),
                      stroke = FALSE,
                      fillOpacity = 0.8
        )
      
   
    } else if (input$view_mode == "footprint") {
      
      leafletProxy("mymap", data = firefoot) %>%
        clearShapes() %>% clearControls() %>%

        addPolygons(data = firefoot,
                    group = "Fire footprint",
                    layerId = ~pixID,
                    fillColor = ~styles[[isolate(input$symbology)]]$palette(firefoot[[isolate(input$symbology)]]),
                    stroke = FALSE,
                    fillOpacity = 0.8
        ) %>%
        
        addLegend(pal = styles[[isolate(input$symbology)]]$palette,
                  values = firefoot[[isolate(input$symbology)]],
                  title = legends[[isolate(input$symbology)]],
                  group = "Fire footprint",
                  position = "bottomright") %>% 

         addLayersControl(overlayGroups = c("Fire footprint"),
                          baseGroups = c("Topography", "Satellite", "Minimal"),
                          options = layersControlOptions(collapsed = FALSE))

      }

  })
 
  
## Restyle map by day selected 
  observeEvent(input$day, {
    
    if (input$view_mode == "timeline") {
    
      # update date box on map
      leafletProxy("mymap") %>%
        removeControl("date") %>%
        addControl(
          html = sprintf(
            "<div style='font-weight:bold;background:white;
                    padding:6px;border-radius:4px'>
           %s
         </div>",
            unlist(dates[[input$day]])
          ),
          position = "topright",
          layerId = "date"
        )  
    
    # send the restyling to javascript    
    var <- paste0("day_", input$day)
    cols <- setNames(
      timeline_pal(fires[[var]]),
      fires$pixID
    )
    
    print(var)
    
    session$sendCustomMessage(
      "restyle",
      list(colours = cols)
    )
    
    # and update date label on slider
    updateSliderInput(
      session,
      "day",
      label = paste(
        "Select day:",
        as.character(unlist(dates[[input$day]]))
      )
    )
    
    message("Sending restyle")
    }
    
  }, ignoreInit = FALSE)
   

## Restyle map by variable   
  observeEvent(input$symbology, {
    
    if (input$view_mode == "footprint") {
      
    style <- styles[[input$symbology]]
    
    cols <- setNames(
      style$palette(firefoot[[style$variable]]),
      firefoot$pixID
    )
    
    session$sendCustomMessage(
      "restyle",
      list(colours = cols)
    )
    
    # update legend
    leafletProxy("mymap") %>%
      clearControls() %>% 
      addLegend(pal = styles[[isolate(input$symbology)]]$palette,
                values = firefoot[[isolate(input$symbology)]],
                title = legends[[input$symbology]],
                group = "Fire footprint",
                position = "bottomright") 
   
    }
    
  }, ignoreInit = FALSE)
  


# Footer information ------------------------------------------------------

# These display pop-ups with text when the input is clicked at the bottom of the sidebar
  
observeEvent(input$link_disclaim, {
    showModal(modalDialog(title = 'Disclaimer',
                          includeHTML("www/disclaimer.html"),
                          size = 'l', 
                          footer = modalButton('Close')))
  })
  
  
  
  
} # end server
