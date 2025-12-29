# Extract methods for dbData with auto-reconnection
# These methods auto-reconnect when accessing db-backed objects

#' @rawNamespace exportMethods("[")
#' @rawNamespace exportMethods("[<-")
NULL

setMethod("[", "dbData", function(x, ...) {
  tryCatch({
    reconnected_obj <- dbReconnect(x)
    return(reconnected_obj@value)
  }, error = function(e) {
    warning("Auto-reconnection failed: ", e$message)
    return(x@value)
  })
})

setMethod("[<-", "dbData", function(x, ..., value) {
  x@value <- value
  return(x)
})
