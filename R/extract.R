#' dbData methods with automatic connection recovery
#'
#' @description
#' Implementation of methods for dbData objects, including
#' automatic connection repair functionality. This facilitates transparent
#' reconnection to databases when connections become invalid, ensuring
#' uninterrupted workflow even when connections time out or are closed.
#'
#' @include generics.R classes.R connection-methods.R

#' Extract method for dbData objects with connection repair
#'
#' @name extract-dbData
#' @description
#' Automatically repairs invalid connections when extracting from dbData objects.
#'
#' @details
#' This method intercepts the extraction operation on dbData objects and
#' ensures that the connection is valid before proceeding using dbReconnect().
#' The extraction is transparent to the user - if reconnection fails, a warning
#' is issued and the original value is returned.
#'
#' @param x A dbData object
#' @return The extracted data
#' @export
setMethod("[", "dbData", function(x, ...) {
  tryCatch(
    {
      reconnected_obj <- dbReconnect(x)
      return(reconnected_obj@value)
    },
    error = function(reconnect_error) {
      warning("Auto-reconnection failed: ", reconnect_error$message)
      return(x@value)
    }
  )
})

#' Assignment method for dbData objects with connection repair
#'
#' @name extract-assign-dbData
#' @description
#' Automatically repairs invalid connections when assigning to dbData objects.
#'
#' @param x A dbData object
#' @param value The value to assign
#' @return The modified dbData object
#' @export
setMethod("[<-", "dbData", function(x, ..., value) {
  # Update the @value slot directly
  x@value <- value
  return(x)
})
