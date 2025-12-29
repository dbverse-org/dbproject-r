#' Connection accessor methods for `dbData` objects
#'
#' @description
#' Get or set the database connection for a `dbData` object.
#'
#' @details 
#' For dbData objects, dynamically retrieves a valid connection, attempting
#' reconnection if the current connection is invalid. This ensures conn() always
#' returns a usable connection. The conn() method is designed as the
#' accessor with auto-reconnection as a convenience feature.
#'
#' @return For getter: The database connection (`DBIConnection`). For setter: The updated object.
#' @name dbData-connection-accessors
#' @include generics.R classes.R connection-registry.R table-reconnection.R
NULL

#' @param x A `dbData` object
#' @rdname dbData-connection-accessors
#' @export
setMethod("conn", "dbData", function(x) {
  current_conn <- NULL
  
  # Get current connection from the most reliable source
  if (!is.null(x@value) && inherits(x@value, "tbl_duckdb_connection")) {
    current_conn <- dbplyr::remote_con(x@value)
  } else if (!is.null(x@value) && !is.null(x@value$src) && !is.null(x@value$src$con)) {
    current_conn <- x@value$src$con
  } else {
    current_conn <- NULL
  }
  
  # If connection is invalid, attempt to get a fresh one
  if (!is.null(current_conn) && !DBI::dbIsValid(current_conn)) {
    fresh_conn <- .reconnect_conn(current_conn)
    if (!is.null(fresh_conn) && DBI::dbIsValid(fresh_conn)) {
      return(fresh_conn)
    }
  }
  
  # Return current connection (may be invalid, but that's the reality)
  return(current_conn)
})

#' @rdname dbData-connection-accessors
#' @param x A `dbData` object
#' @param value A `DBIConnection` object to set as the new connection.
#' @details 
#' For dbData objects, updates connection storage locations and recreates
#' any tbl_duckdb_connection objects with the new connection to ensure consistency.
#' @export
setReplaceMethod("conn", "dbData", function(x, value) {
  # If value slot contains a tbl_duckdb_connection object, recreate it with new connection
  if (!is.null(x@value) && inherits(x@value, "tbl_duckdb_connection") && !is.null(value)) {
    x@value <- .reconnect_tbl_duckdb(x@value, value)
  }
  
  # Update the value$src$con pattern if available
  if (!is.null(x@value) && !is.null(x@value$src)) {
    x@value$src$con <- value
  }
  
  return(x)
})

#' Reconnection methods for database objects
#'
#' @description
#' Reconnect database connections for `dbData` and `DBIConnection` objects.
#' These methods handle automatic reconnection when database connections become invalid.
#'
#' @details 
#' The base method for dbData objects that uses the robust dbReconnect() function
#' and updates the object with the new connection. Unlike conn() which is used for
#' routine connection access, dbReconnect() is specifically for explicit object repair
#' when you need to fix a broken dbData object and update it in-place.
#'
#' @param x A `dbData` object or `DBIConnection` object to reconnect
#' @return For `dbData` objects: the updated object with reconnected connection.
#'   For `DBIConnection` objects: a new valid connection or NULL if reconnection fails.
#' @name dbReconnect-dbData
#' @rdname dbReconnect-dbData
NULL

#' @rdname dbReconnect-dbData
#' @export
setMethod("dbReconnect", "dbData", function(x) {
  current_conn <- conn(x)
  if (!is.null(current_conn) && !DBI::dbIsValid(current_conn)) {
    new_conn <- .reconnect_conn(current_conn)
    if (!is.null(new_conn) && DBI::dbIsValid(new_conn)) {
      conn(x) <- new_conn
      
      # For objects with tbl_duckdb_connection values, recreate with new connection
      if (!is.null(x@value) && inherits(x@value, "tbl_duckdb_connection")) {
        x@value <- .reconnect_tbl_duckdb(x@value, new_conn)
      }
    }
  }
  return(x)
})

#' @rdname dbReconnect-dbData
#' @details
#' Method for raw DBIConnection objects that uses the internal reconnection function
#' @export
setMethod("dbReconnect", "DBIConnection", function(x) {
  return(.reconnect_conn(x))
})
