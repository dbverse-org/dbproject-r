#' Reconnect a `tbl_duckdb_connection` object to a new connection
#' 
#' @description
#' Internal function to handle reconnection of `tbl_duckdb_connection` objects to new
#' database connections. Handles both named tables and lazy queries.
#' @param tbl_duckdb_obj A `tbl_duckdb_connection` object that needs reconnection
#' @param new_conn A new DuckDB database connection to reconnect to
#' @return Updated `tbl_duckdb_connection` object or the original object if reconnection fails
#' @keywords internal
#' @noRd
.reconnect_tbl_duckdb <- function(tbl_duckdb_obj, new_conn) {
  if (is.null(tbl_duckdb_obj) || !inherits(tbl_duckdb_obj, "tbl_duckdb_connection") || is.null(new_conn)) {
    return(tbl_duckdb_obj)
  }
  
  table_name <- dbplyr::remote_name(tbl_duckdb_obj)
  
  if (!is.null(table_name)) {
    # Named table: reconnect directly if it still exists
    if (DBI::dbExistsTable(new_conn, table_name)) {
      return(dplyr::tbl(new_conn, table_name))
    } else {
      warning("Table '", table_name, "' no longer exists after reconnection. ",
              "This may have been a temporary table that was lost when the connection closed.")
      return(tbl_duckdb_obj)
    }
  } else {
    # Lazy query: extract SQL and create new tbl with swapped connection
    # The SQL query structure is preserved - we just swap the dead connection for a live one
    tryCatch({
      sql <- dbplyr::sql_render(tbl_duckdb_obj)
      new_tbl <- dplyr::tbl(new_conn, dbplyr::sql(sql))
      return(new_tbl)
    }, error = function(e) {
      warning("Failed to reconnect lazy query: ", e$message)
      return(tbl_duckdb_obj)
    })
  }
}