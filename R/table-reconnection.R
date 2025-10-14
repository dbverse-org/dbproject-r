#' Reconnect a `tbl_duckdb_connection` object to a new connection
#'
#' @description
#' Internal function to handle reconnection of `tbl_duckdb_connection` objects to new
#' database connections.
#' @param tbl_duckdb_connection A `tbl_duckdb_connection` object that needs reconnection
#' @param new_conn A new DuckDB database connection to reconnect to
#' @return Updated `tbl_duckdb_connection` object or the original object if reconnection fails
#' @keywords internal
#' @noRd
.reconnect_tbl_duckdb <- function(tbl_duckdb_obj, new_conn) {
  if (
    is.null(tbl_duckdb_obj) ||
      !inherits(tbl_duckdb_obj, "tbl_duckdb_connection") ||
      is.null(new_conn)
  ) {
    return(tbl_duckdb_obj)
  }

  table_name <- dbplyr::remote_name(tbl_duckdb_obj)

  if (!is.null(table_name)) {
    if (DBI::dbExistsTable(new_conn, table_name)) {
      return(dplyr::tbl(new_conn, table_name))
    } else {
      warning(
        "Table '",
        table_name,
        "' no longer exists after reconnection. ",
        "This may have been a temporary table that was lost when the connection closed."
      )
      return(tbl_duckdb_obj)
    }
  } else {
    # For lazy tables/views without names, we cannot reliably recover them
    # after reconnection since they were never materialized. This follows
    # R/DBI conventions where temporary objects are lost on disconnection.
    warning("Lazy table/view cannot be recovered after reconnection. ")
    return(tbl_duckdb_obj)
  }
}
