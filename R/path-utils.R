#' Normalize a file path consistently across systems
#'
#' @param p Character. A file path to normalize
#' @return Normalized path or the input if normalization fails
#' @keywords internal
#' @noRd
.norm_path <- function(p) {
  if (is.null(p) || p == "" || p == ":memory:") {
    return(p)
  }

  # Normalize the path
  np <- tryCatch(
    normalizePath(p, winslash = "/", mustWork = FALSE),
    error = function(e) p
  )

  # On macOS, strip the /private prefix for consistency
  if (.Platform$OS.type == "unix" && startsWith(np, "/private/")) {
    np <- substring(np, 9) # Remove "/private" prefix
  }

  return(np)
}

#' Extract database directory from a connection
#'
#' @param con A database connection
#' @return Path to the database file, or NULL
#' @keywords internal
#' @noRd
.get_dbdir <- function(con) {
  # Handle NULL case
  if (is.null(con)) {
    return(NULL)
  }

  # Extract dbdir from DuckDB connection
  if (inherits(con, "duckdb_connection")) {
    tryCatch(
      {
        # Check for dbdir attribute (explicitly set)
        path <- attr(con, "dbdir")
        if (!is.null(path)) {
          return(.norm_path(path))
        }

        # Try to access the driver directly
        if (
          !is.null(con@driver) &&
            inherits(con@driver, "duckdb_driver") &&
            !is.null(con@driver@dbdir)
        ) {
          return(.norm_path(con@driver@dbdir))
        }

        # Couldn't determine the path
        return(NULL)
      },
      error = function(e) {
        return(NULL)
      }
    )
  }
  return(NULL)
}
