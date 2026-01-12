# No include directive needed as this should be loaded first
#' Generic Function Definitions for dbverse
#'
#' @description
#' This file contains all generic function definitions for the dbverse ecosystem.
#' All generics are defined here once to avoid duplicate definition errors.
#' Method implementations are defined in their respective files.
#'
#' @details
#' Centralizing generic definitions helps avoid the "no method found for function..."
#' error that occurs when the same generic is defined in multiple files.
#'
#' @name dbverse-generics
#' @keywords internal
#' @import methods
NULL

#' Connection accessor methods for dbData objects
#'
#' @description
#' These methods provide a unified interface for accessing and setting database connections
#' across all dbverse packages. They handle different connection storage patterns
#' across various subclasses.
#'
#' @details
#' The connection accessor methods support multiple implementation patterns:
#'
#' 1. Nested connection: Some classes (like dbMatrix) store connections in `value$src$con`
#' 2. dbplyr connections: Objects with tbl_duckdb_connection values can use dbplyr::remote_con()
#'
#' The implementation automatically tries these access patterns in order of specificity,
#' falling back to more generic approaches if needed.
#'
#' @name dbData-connection-accessors
#' @aliases conn
#' @param x A dbData object
#' @param value A database connection
#' @return For getter: The database connection. For setter: The updated object
#' @seealso [dbData-class]
#' @export conn
methods::setGeneric("conn", function(x) standardGeneric("conn"))

#' @rdname dbData-connection-accessors
#' @export
methods::setGeneric("conn<-", function(x, value) {
  standardGeneric("conn<-")
})

#' Reconnect database connection for dbData objects
#'
#' @description
#' Reconnects invalid database connections for dbData objects, updating the
#' object with the new valid connection.
#'
#' @name dbReconnect
#' @param x A dbData object
#' @return The dbData object with an updated connection
#' @export
methods::setGeneric("dbReconnect", function(x) standardGeneric("dbReconnect"))

#' Convert lazy table to named view
#'
#' @name to_view
#' @param x A lazy table object (tbl_duckdb_connection)
#' @param name Character name to assign view within database
#' @param temporary Logical, if TRUE (default), the view will be deleted after the session ends
#' @param overwrite Logical, if TRUE (default), the view will overwrite an existing view
#' @param ... Additional arguments passed to DBI::dbExecute
#' @export
methods::setGeneric(
  "to_view",
  function(x, name, temporary = TRUE, overwrite = TRUE, ...) {
    standardGeneric("to_view")
  }
)

#' List remote tables, temporary tables, and views
#'
#' @description
#' A generic function to list tables, temporary tables, and views in a database connection.
#' This provides an enhanced view over DBI::dbListTables with categorization.
#'
#' @name dbList
#' @param conn A DBI database connection
#' @param ... Additional arguments passed to methods
#' @return Method implementations may return different formats, typically a categorized list
#' @seealso [DBI::dbListTables()]
#' @export
methods::setGeneric("dbList", function(conn, ...) standardGeneric("dbList"))

#' Load a dbverse object from the database
#'
#' @description
#' Generic function to reconstruct dbverse objects (dbMatrix, dbSpatial, etc.)
#' from tables stored in a database connection.
#'
#' @name dbLoad
#' @param conn A DBI database connection
#' @param name Character name of the table/view in the database
#' @param class Character class name of the object to load (e.g., "dbMatrix", "dbSpatial")
#' @param ... Additional arguments passed to specific methods
#' @return A dbverse object of the specified class
#' @export
methods::setGeneric("dbLoad", function(conn, name, class, ...) standardGeneric("dbLoad"))
