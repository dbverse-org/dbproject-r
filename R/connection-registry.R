#' Registry to track live connections
#'
#' @description
#' The registry provides O(1) lookups from database file paths
#' to cached live connections. This enables fast reconnection
#' and connection de-duplication when a connection becomes invalid.
#'
#' Entries are keyed by normalized database file path.
#' Live connections are stored under `paste0("conn:", dir)`.
#' @keywords internal
.db_registry <- new.env(parent = emptyenv())

.reg_key <- function(dbdir) {
  if (is.null(dbdir) || length(dbdir) != 1 || is.na(dbdir) ||
      dbdir == "" || dbdir == ":memory:") {
    return(NULL)
  }
  paste0("conn:", .norm_path(dbdir))
}

.reg_conn <- function(dbdir) {
  key <- .reg_key(dbdir)
  if (is.null(key)) return(NULL)

  cached <- .db_registry[[key]]
  if (!is.null(cached) && DBI::dbIsValid(cached)) return(cached)
  if (!is.null(cached)) rm(list = key, envir = .db_registry)
  NULL
}

.reg_set_conn <- function(dbdir, conn) {
  key <- .reg_key(dbdir)
  if (is.null(key) || is.null(conn) || !DBI::dbIsValid(conn)) {
    return(invisible(FALSE))
  }
  .db_registry[[key]] <- conn
  invisible(TRUE)
}

.reg_get_or_connect <- function(dbdir) {
  cached <- .reg_conn(dbdir)
  if (!is.null(cached)) return(cached)

  if (is.null(.reg_key(dbdir))) {
    return(.connect_duckdb_lock_safe(dbdir = ":memory:"))
  }

  con <- .connect_duckdb_lock_safe(dbdir = .norm_path(dbdir))
  .reg_set_conn(dbdir, con)
  con
}

#' Reset the dbProject registry
#'
#' @description Removes all entries from the dbProject registry
#' @return Invisibly returns TRUE
#' @keywords internal
#' @noRd
.reg_reset <- function() {
  rm(list = ls(envir = .db_registry), envir = .db_registry)
  return(invisible(TRUE))
}