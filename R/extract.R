# Extract methods for dbData with auto-reconnection
# These methods auto-reconnect when accessing db-backed objects

#' Extract and replace methods for dbData objects
#'
#' @description
#' Provides extraction (`[`) and replacement (`[<-`) methods for `dbData` objects.
#' The extractor attempts to auto-reconnect via [dbReconnect()] before returning
#' the underlying database-backed value.
#'
#' @param x A `dbData` object.
#' @param ... Additional arguments passed to the extractor.
#' @param value Replacement value for `[<-`.
#' @return For `[`: the underlying value stored in the object. For `[<-`: the updated `dbData`.
#' @name dbData-extract
#'
#' @aliases [ dbData-extract
#' @aliases [,dbData-method
#' @aliases [<-,dbData-method
#'
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
