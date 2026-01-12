# validation.R
# Centralized input validation functions for dbverse packages
# Used by: dbMatrix, dbSpatial, GiottoDB

#' Validate database connection
#' @param conn A DBI connection object
#' @keywords internal
#' @export .check_con
.check_con <- function(conn) {
  if (missing(conn)) {
    stop("Please provide a connection")
  }

  if (!DBI::dbIsValid(conn)) {
    stop("Stale connection. Reconnect your db connection.")
  }

  if (!inherits(conn, "duckdb_connection")) {
    stop("conn must be a duckdb connection. Use duckdb drv in DBI::dbConnect()")
  }
}

#' Validate table name
#' @param name Character, table name
#' @keywords internal
#' @export .check_name
.check_name <- function(name) {
  if (missing(name)) {
    stop("Please provide a table name")
  }

  if (!is.character(name)) {
    stop("name must be a character string")
  }

  # Table names should not start with a number
  if (grepl("^[0-9]", name)) {
    stop("Table names should not start with a number")
  }

  # Reserved SQL keywords
  reserved <- c(
    "intersect", "union", "except", "select", "from", "where",
    "group", "by", "limit", "create", "table", "insert"
  )
  if (tolower(name) %in% reserved) {
    stop("Table name cannot be a RESERVED word. Try another name.")
  }
}

#' Validate overwrite parameter and handle existing objects
#' @param conn DBI connection
#' @param overwrite Logical or "PASS" token
#' @param name Table name
#' @param skip_value_check Logical, if TRUE skip value-based checks (used by dbMatrix)
#' @keywords internal
#' @export .check_overwrite
.check_overwrite <- function(conn, overwrite, name, skip_value_check = FALSE) {
  # "PASS" token for lazy tables that shouldn't be overwritten

  if (identical(overwrite, "PASS")) {
    return(invisible(NULL))
  }

  if (!is.logical(overwrite)) {
    stop("overwrite must be logical")
  }

  object_exists <- DBI::dbExistsTable(conn, name)

  if (!overwrite && object_exists) {
    stop("Object already exists. Set overwrite = TRUE to overwrite.")
  }

  if (overwrite && object_exists) {
    # Check if it's a view
    is_view <- DBI::dbGetQuery(
      conn,
      glue::glue(
        "SELECT COUNT(*) > 0 AS is_view
         FROM duckdb_views()
         WHERE view_name = '{name}'"
      )
    )$is_view

    if (is_view) {
      DBI::dbExecute(conn, glue::glue("DROP VIEW IF EXISTS {name}"))
    } else {
      DBI::dbRemoveTable(conn, name)
    }
  }

  invisible(NULL)
}

#' Validate dplyr tbl object
#' @param tbl A tbl_duckdb_connection object
#' @keywords internal
#' @export .check_tbl
.check_tbl <- function(tbl) {
  if (missing(tbl)) {
    stop("Please provide a table")
  }

  if (!inherits(tbl, "tbl_duckdb_connection")) {
    stop("Please provide a table in a DuckDB database.")
  }
}

#' Generate unique table names
#' @param prefix Character prefix for table name
#' @return Character, unique table name
#' @keywords internal
#' @export
unique_table_name <- function(prefix = "db") {
  vals <- c(letters, LETTERS, 0:9)
  suffix <- paste0(sample(vals, 10, replace = TRUE), collapse = "")
  paste0(prefix, "_", suffix)
}
