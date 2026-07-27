## Utility functions to query FIRMS data

# function to prepare query from parameters 

prep_query <- function(base_url, 
                       map_key, 
                       data_source,
                       bbox,
                       range,
                       fromdate){
  
  # prepare query url
  query_url = paste0(base_url, map_key, "/", data_source, "/", bbox, "/", range, "/", fromdate)
  
  req <- request(query_url) |>
    req_retry(
      max_tries = 5,
      backoff = ~ runif(1, 1, 2) * 2^.x
    )
  
}

## Download the data using query (wrapper function). Returns a data frame
get_firms <- function(request) {
  
  tmp <- tempfile(fileext = ".csv") # prep temp location
  
  tryCatch({
    
    req_perform(request, path = tmp)
    
    readr::read_csv(tmp, show_col_types = FALSE)
    
  }, error = function(e) {
    
    warning(e$message)
    
    NULL
    
  })
}