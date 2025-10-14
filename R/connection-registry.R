#' Registry to track dbProject mappings
#'
#' @description
#' The registry provides O(1) lookups from database file paths
#' to their corresponding project paths. This enables fast
#' reconnection when a connection becomes invalid.
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
