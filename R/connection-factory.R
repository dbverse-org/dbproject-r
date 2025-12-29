#' Create a new connection to a database file
#'
#' @param con Original connection (potentially invalid)
#' @param dbdir Optional database directory path
#' @return New valid connection or NULL if reconnection fails
#' @keywords internal
#' @noRd
.db_recon <- function(con, dbdir = NULL) {
  if (is.null(dbdir)) {
    dbdir <- tryCatch(
      {
        .get_dbdir(con)
      },
      error = function(e) {
        NULL
      }
    )
  }

  # If no dbdir available, create an in-memory connection
  if (is.null(dbdir) || dbdir == "" || dbdir == ":memory:") {
    # Create new in-memory connection
    tryCatch(
      {
        drv <- duckdb::duckdb(dbdir = ":memory:")
        new_con <- DBI::dbConnect(drv)
        attr(new_con, "dbdir") <- ":memory:"
        return(new_con)
      },
      error = function(e) {
        return(NULL)
      }
    )
  }

  # Otherwise reconnect to existing database file
  tryCatch(
    {
      # First check if the file exists
      if (!file.exists(dbdir)) {
        return(NULL)
      }

      drv <- duckdb::duckdb(dbdir = dbdir)
      new_con <- DBI::dbConnect(drv)

      # Store database path as attribute for future reconnection
      attr(new_con, "dbdir") <- dbdir

      return(new_con)
    },
    error = function(e) {
      return(NULL)
    }
  )
}

#' Reconnect to a database via its project
#'
#' @param path Project path
#' @param dir Database path
#' @return New connection or NULL if reconnection fails
#' @keywords internal
#' @noRd
.proj_recon <- function(path, dir) {
  # Check if project path exists
  if (!dir.exists(path)) {
    return(NULL)
  }

  # Create a new connection
  new_con <- NULL
  tryCatch(
    {
      drv <- duckdb::duckdb(dbdir = dir)
      new_con <- DBI::dbConnect(drv)

      # Store database path as attribute for future reconnection
      attr(new_con, "dbdir") <- dir

      # Re-register the connection
      .reg_add(dir, path)
    },
    error = function(e) {}
  )

  return(new_con)
}

#' Database Reconnection
#' 
#' @description
#' Internal function used by the [dbReconnect()] and [conn()] generics.
#' Reconnection is triggered when [DBI::dbIsValid()] returns `FALSE`, indicating 
#' the connection has been lost, expired, or closed. Common scenarios include 
#' network interruptions, db restarts, timeouts, or [DBI::dbDisconnect()].
#' 
#' @details
#' This function safely checks if a database connection is valid and attempts to
#' reconnect if it's not. The reconnection process follows these steps:
#' 1. Check if the connection is valid - if yes, return it as-is
#' 2. If invalid, get the database directory from the connection
#' 3. If database directory exists, look for a project in the registry
#' 4. If project found, attempt to reconnect via the project
#' 5. If project reconnection fails or no project found, fall back to direct reconnection
#'
#' @param con A database connection object (DBI connection), even if invalid
#' @return A valid connection object or NULL if all reconnection attempts fail
#' @keywords internal
.reconnect_conn <- function(con) {
  tryCatch({
    if (is.null(con)) {
      return(con)
    }

    # Safely check if connection is valid
    is_valid <- tryCatch(
      {
        valid <- DBI::dbIsValid(con)
        valid
      },
      error = function(e) {
        FALSE
      }
    )

    # Return as-is if connection is valid
    if (is_valid) {
      return(con)
    }

    dir <- NULL

    # Step 1: Try to get dbdir from attribute first (most reliable)
    dir <- tryCatch(
      {
        path <- attr(con, "dbdir")
        if (!is.null(path) && path != "") {
          .norm_path(path)
        } else {
          NULL
        }
      },
      error = function(e) {
        NULL
      }
    )

    # Step 2: If dir is still NULL, try to directly access
    if (is.null(dir)) {
      dir <- tryCatch(
        {
          dbdir <- con@driver@dbdir
          if (!is.null(dbdir) && dbdir != "") {
            .norm_path(dbdir)
          } else {
            NULL
          }
        },
        error = function(e) {
          NULL
        }
      )
    }

    # Step 3: If no dbdir available, try to reconnect directly
    if (is.null(dir) || dir == "" || dir == ":memory:") {
      return(.db_recon(con, dir))
    }

    # Step 4: Check registry for project connection
    proj_path <- .reg_find(dir)
    if (!is.null(proj_path)) {
      tryCatch(
        {
          new_con <- .proj_recon(proj_path, dir)
          if (!is.null(new_con)) {
            is_valid <- tryCatch(DBI::dbIsValid(new_con), error = function(e) {
              FALSE
            })
            if (is_valid) return(new_con)
          }
        },
        error = function(e) {}
      )
    }

    # Step 5: Fallback to direct reconnection if project reconnect failed
    return(.db_recon(con, dir))
    
  }, error = function(e) {
    warning("Failed to reconnect database connection: ", e$message)
    return(NULL)
  })
}