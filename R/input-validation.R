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

  if (!is.character(name) || length(name) != 1L || is.na(name)) {
    stop("name must be a single character string")
  }

  # Names are used directly in SQL, so allow only letters, digits and "_"
  if (!grepl("^[[:alpha:]_][[:alnum:]_]*$", name)) {
    stop(
      "Invalid table name '", name, "'. Use only letters, numbers and '_', ",
      "and do not start with a number (e.g. 'pbmc_3k')."
    )
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
    if (is_view(conn, name)) {
      DBI::dbExecute(conn, glue::glue("DROP VIEW IF EXISTS {name}"))
    } else {
      DBI::dbRemoveTable(conn, name)
    }
  }

  invisible(NULL)
}

#' Check if a database object is a VIEW
#' @param conn DBI connection (must be duckdb)
#' @param name Character, object name to check
#' @return Logical, TRUE if the object is a VIEW
#' @keywords internal
#' @export
is_view <- function(conn, name) {
  if (!inherits(conn, "duckdb_connection")) {
    stop("conn must be a duckdb connection")
  }
  if (!is.character(name) || length(name) != 1L || is.na(name)) {
    stop("name must be a single non-NA character string")
  }

  res <- DBI::dbGetQuery(
    conn,
    glue::glue(
      "SELECT COUNT(*) > 0 AS is_view
       FROM duckdb_views()
       WHERE view_name = '{name}'"
    )
  )

  if (is.null(res) || nrow(res) == 0 || !("is_view" %in% names(res))) {
    return(FALSE)
  }

  val <- res$is_view[[1]]
  isTRUE(val) && !is.na(val)
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
  # tempfile() makes unique names without touching the user's random seed
  basename(tempfile(paste0(prefix, "_")))
}
