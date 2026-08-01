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
  

# authentication ----------------------------------------------------------

  # creds <- data.frame(
  #   user = Sys.getenv("FIREUSER"),
  #   password = Sys.getenv("FIREPW")
  # )
  # 
  # # authorisation
  # res_auth <- secure_server(
  #   check_credentials = check_credentials(creds)
  # )
  

  ## Initialise map
  output$mymap <- renderLeaflet({
    # req(res_auth)
    # req(res_auth$user)
    bgmap %>% 
      
      addLayersControl(overlayGroups = c("Fire footprint"),
                       baseGroups = c("Topography", "Satellite", "Minimal"),
                       options = layersControlOptions(collapsed = FALSE))
  }) 
  
# Tracking / debugging ----------------------------------------------------------

# observe({
#   print(input$day)
# })

# Map updates -------------------------------------------------------------

  observe({
    # req(res_auth)
    # req(res_auth$user)
    
    if (input$view_mode == "timeline") {

      leafletProxy("mymap", data = fires) %>%
        clearShapes() %>% 
        clearControls() %>%
        
        addPolygons(data = fires,
                      layerId = ~pixID,
                      group = "fire_day",
                      fillColor = ~styles$frp$palette(fires[[paste0("day_", isolate(input$day))]]),
                      stroke = FALSE,
                      fillOpacity = 0.8
        ) %>%
        
        addLegend(pal = styles$frp$palette,
                  values = c(0:FRPmax),
                  title = legends[["frp"]],
                  #group = "Fire footprint",
                  position = "bottomright") 
      
   
    } else if (input$view_mode == "footprint") {
      
      leafletProxy("mymap", data = firefoot) %>%
        clearShapes() %>% 
        clearControls() %>%

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
                  #group = "Fire footprint",
                  position = "bottomright") 

      }

  })
 
  
## Restyle map by day selected 
  observeEvent(input$day, {
    # req(res_auth)
    # req(res_auth$user)
    
    if (input$view_mode == "timeline") {
    
      # update date box on map
      leafletProxy("mymap") %>%
        removeControl("date") %>% 
        #clearControls() %>%
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
    
    # # update sparkline
    # plotlyProxy("sparkline") %>% 
    # plotlyProxyInvoke("deleteTraces", list(1)) %>% 
    #   plotlyProxyInvoke(
    #     "addTraces",
    #     list(
    #       x = list(input$day),
    #       y = list(filter(area, day == input$day)$area_km2),
    #       type = "scatter",
    #       mode = "markers",
    #       marker = list(size = 12, color = "#d95f02"),
    #       showlegend = FALSE, cliponaxis = FALSE, hoverinfo = "skip"
    #     ))
    
    
    } # end timeline actions
  }, ignoreInit = FALSE) # end day observer
   

## Restyle map by variable   
  observeEvent(input$symbology, {
    # req(res_auth)
    # req(res_auth$user)
    
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
                #group = "Fire footprint",
                position = "bottomright") 
   
    }
    
  }, ignoreInit = FALSE)
  


# Sparkline ---------------------------------------------------------------

# a plotly trace that shows area affected, with a moving point for date selected
# this just sets up the plot, and the day observer will send the proxy update
  
# output$sparkline <- renderPlotly({
#   spark %>% 
#     add_markers(
#       x = isolate(input$day),
#       y = filter(area, day == isolate(input$day))$area_km2,
#       marker = list(
#         size = 12, color = "#d95f02"),
#       hoverinfo = "skip",
#       cliponaxis = FALSE, 
#       showlegend = FALSE
#     )
# })  

  

# Habitats affected -------------------------------------------------------

output$habitats <- renderPlotly({
  
  hab_areas$habitat <- factor(hab_areas$habitat, 
                              levels = hab_areas$habitat[order(hab_areas$area_km2)], ordered=T)
  
  p <- ggplot(hab_areas, aes(x = habitat, y = area_km2)) +
    labs(title = "Habitats affected", x = "", y = "Area (km²)") +
    geom_col(width = 0.5, fill = "#f6b338") + 
    coord_flip() +
    theme_bw() 
    
    ggplotly(p)
                
  
})  
  
# Footer information ------------------------------------------------------

# These display pop-ups with text when the input is clicked at the bottom of the sidebar
  
observeEvent(input$link_disclaim, {
  # req(res_auth)
  # req(res_auth$user)
  
    showModal(modalDialog(title = 'Disclaimer',
                          includeHTML("www/disclaimer.html"),
                          size = 'l', 
                          footer = modalButton('Close')))
  })
  
  
  
  
} # end server
