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

#' Find a cached live connection for a database path
#'
#' @param dir Normalized path to database file
#' @return A valid DBIConnection or NULL
#' @keywords internal
#' @noRd
.reg_conn <- function(dir) {
  if (is.null(dir) || dir == "" || dir == ":memory:") return(NULL)
  dir <- .norm_path(dir)
  key <- paste0("conn:", dir)
  cached <- .db_registry[[key]]
  if (!is.null(cached) && DBI::dbIsValid(cached)) return(cached)
  NULL
}

#' Store a live connection in the registry
#'
#' @param dir Normalized path to database file
#' @param conn A valid DBIConnection
#' @keywords internal
#' @noRd
.reg_set_conn <- function(dir, conn) {
  if (is.null(dir) || dir == "" || dir == ":memory:") return(invisible(FALSE))
  dir <- .norm_path(dir)
  .db_registry[[paste0("conn:", dir)]] <- conn
  invisible(TRUE)
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