#' List remote tables, temporary tables, and views
#' @inheritParams DBI::dbListTables
#' @export
#' @description
#' Pretty prints tables, temporary tables, and views in the database.
#' @details
#' Similar to DBI::dbListTables, but categorizes tables into three categories:
#' * Tables
#' * Temporary Tables (these will be removed when the connection is closed)
#' * Views (these may be removed when the connection is closed)
#'
#' @concept dbData
setMethod('dbList', signature(conn = 'DBIConnection'), function(conn) {
  # Query to get table types
  query <- "SELECT table_name, table_type FROM information_schema.tables"
  table_types <- DBI::dbGetQuery(conn, query)

  # Categorize tables based on their types
  tables <- dplyr::filter(table_types, table_type == 'BASE TABLE')
  views <- dplyr::filter(
    table_types,
    grepl("VIEW", table_type, ignore.case = TRUE)
  )
  temp_tables <- dplyr::filter(
    table_types,
    grepl("TEMPORARY", table_type, ignore.case = TRUE)
  )

  print_category <- function(category_name, items) {
    cat(crayon::green(paste0(category_name, ": \n")))
    if (length(items) == 0) {
      cat("\n")
    } else {
      print(items)
    }
  }

  # Print the results
  print_category("Tables", tables$table_name)
  print_category("Temporary Tables", temp_tables$table_name)
  print_category("Views", views$table_name)
})
