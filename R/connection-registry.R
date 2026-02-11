#' Registry to track dbProject mappings and live connections
#'
#' @description
#' The registry provides O(1) lookups from database file paths
#' to their corresponding project paths. This enables fast
#' reconnection when a connection becomes invalid.
#'
#' Entries are keyed by normalized database file path.
#' Project paths are stored under `dir`, live connections under
#' `paste0("conn:", dir)` to avoid collisions.
#' @keywords internal
.db_registry <- new.env(parent = emptyenv())

#' Add a dbProject mapping to registry
#'
#' @param dir Path to database file
#' @param proj Path to project
#' @return boolean indicating if addition was successful
#' @keywords internal
#' @noRd
.reg_add <- function(dir, proj) {
  # Skip NULL, empty or memory paths
  if (is.null(dir) || dir == "" || dir == ":memory:") {
    return(invisible(FALSE))
  }

  # Add to registry
  .db_registry[[dir]] <- proj
  return(invisible(TRUE))
}

#' Find project associated with a database
#'
#' @param dir Path to database file
#' @return Project path or NULL if not found in registry
#' @keywords internal
#' @noRd
.reg_find <- function(dir) {
  # Skip NULL, empty or memory paths
  if (is.null(dir) || dir == "" || dir == ":memory:") {
    return(NULL)
  }

  # Lookup in registry
  .db_registry[[dir]]
}

#' Find a cached live connection for a database path
#'
#' @param dir Normalized path to database file
#' @return A valid DBIConnection or NULL
#' @keywords internal
#' @noRd
.reg_conn <- function(dir) {
  if (is.null(dir) || dir == "" || dir == ":memory:") return(NULL)
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