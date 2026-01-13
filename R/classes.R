#' Virtual Base Class for Database-Backed Data Objects
#'
#' @description
#' `dbData` is a virtual base class for database-backed objects in the dbverse ecosystem.
#' This class provides a common interface for objects that are backed by database tables.
#' It is extended by concrete classes like dbMatrix and dbSpatial that provide specific
#' implementations.
#'
#' @section Extensibility:
#' When creating a new type of database-backed object, extend this class to ensure
#' compatibility with the dbverse ecosystem.
#'
#' @slot value tbl_duckdb_connection that represents the data in the database
#' @slot name name of table within database that contains the data
#' @name dbData-class
#' @import methods
#' @export
methods::setClass(
  Class = 'dbData',
  contains = c('VIRTUAL'),
  slots = list(
    value = 'ANY',
    name = 'character'
  ),
  prototype = list(
    value = NULL,
    name = NA_character_
  )
)
