# Connection methods and reconnection logic for dbverse
# Includes: conn(), conn<-(), dbReconnect() methods and internal reconnection helpers

#' @include generics.R classes.R connection-registry.R table-reconnection.R

# Internal Helpers ----

# Resolve database directory path
# Pre-resolve paths before passing to connections package
.resolve_dbdir <- function(...) {
  if (length(list(...)) == 0) return(NULL)
  normalizePath(file.path(...), winslash = "/", mustWork = FALSE)
}

# Direct database reconnection
.db_recon <- function(con, dbdir = NULL) {
  if (is.null(dbdir)) {
    dbdir <- tryCatch(.get_dbdir(con), error = function(e) NULL)
  }

  # In-memory fallback
  if (is.null(dbdir) || dbdir == "" || dbdir == ":memory:") {
    return(tryCatch({
      drv <- duckdb::duckdb(dbdir = ":memory:")
      new_con <- DBI::dbConnect(drv)
      attr(new_con, "dbdir") <- ":memory:"
      new_con
    }, error = function(e) NULL))
  }

  # File-based reconnection
  tryCatch({
    if (!file.exists(dbdir)) return(NULL)
    drv <- duckdb::duckdb(dbdir = dbdir)
    new_con <- DBI::dbConnect(drv)
    attr(new_con, "dbdir") <- dbdir
    .reg_set_conn(dbdir, new_con)
    new_con
  }, error = function(e) NULL)
}

# Main reconnection strategy
# Used by dbReconnect() and conn() methods
.reconnect_conn <- function(con) {
  tryCatch({
    if (is.null(con)) return(con)

    # Check validity
    is_valid <- tryCatch(DBI::dbIsValid(con), error = function(e) FALSE)
    if (is_valid) return(con)

    # Get database directory
    dir <- tryCatch({
      path <- attr(con, "dbdir")
      if (!is.null(path) && path != "") .norm_path(path) else NULL
    }, error = function(e) NULL)

    if (is.null(dir)) {
      dir <- tryCatch({
        dbdir <- con@driver@dbdir
        if (!is.null(dbdir) && dbdir != "") .norm_path(dbdir) else NULL
      }, error = function(e) NULL)
    }

    # In-memory or no dir: direct reconnect (no caching possible)
    if (is.null(dir) || dir == "" || dir == ":memory:") {
      return(.db_recon(con, dir))
    }

    # Check registry for an existing valid connection to this db
    cached <- .reg_conn(dir)
    if (!is.null(cached)) return(cached)

    # Fallback to direct reconnection
    .db_recon(con, dir)
  }, error = function(e) {
    warning("Failed to reconnect: ", e$message)
    NULL
  })
}

# conn() Methods ----

#' Connection accessor methods for `dbData` objects
#'
#' @description Get or set the database connection for a `dbData` object.
#' @details Auto-reconnects if the current connection is invalid.
#' @param x A `dbData` object
#' @param value A `DBIConnection` object
#' @return For getter: `DBIConnection`. For setter: Updated object.
#' @name dbData-connection-accessors
#' @aliases conn,dbData-method
#' @export
setMethod("conn", "dbData", function(x) {
  current_conn <- NULL
  
  if (!is.null(x@value) && inherits(x@value, "tbl_duckdb_connection")) {
    current_conn <- tryCatch(dbplyr::remote_con(x@value), error = function(e) NULL)
  } else if (!is.null(x@value) && !is.null(x@value$src) && !is.null(x@value$src$con)) {
    current_conn <- x@value$src$con
  }
  
  # Auto-reconnect if invalid
  if (!is.null(current_conn) && !DBI::dbIsValid(current_conn)) {
    fresh_conn <- .reconnect_conn(current_conn)
    if (!is.null(fresh_conn) && DBI::dbIsValid(fresh_conn)) {
      return(fresh_conn)
    }
  }
  
  current_conn
})

#' @rdname dbData-connection-accessors
#' @export
setReplaceMethod("conn", "dbData", function(x, value) {
  if (!is.null(x@value) && inherits(x@value, "tbl_duckdb_connection") && !is.null(value)) {
    x@value <- .reconnect_tbl_duckdb(x@value, value)
  }
  if (!is.null(x@value) && !is.null(x@value$src)) {
    x@value$src$con <- value
  }
  x
})

# dbReconnect() Methods ----

#' @rdname dbReconnect
#' @export
setMethod("dbReconnect", "dbData", function(x) {
  # Extract connection from x@value (avoid conn(x) auto-reconnect = avoid no-op)
  current_conn <- NULL
  if (!is.null(x@value) && inherits(x@value, "tbl_duckdb_connection")) {
    current_conn <- tryCatch(dbplyr::remote_con(x@value), error = function(e) NULL)
  } else if (!is.null(x@value) && !is.null(x@value$src) && !is.null(x@value$src$con)) {
    current_conn <- x@value$src$con
  }

  if (!is.null(current_conn) && !DBI::dbIsValid(current_conn)) {
    new_conn <- .reconnect_conn(current_conn)
    if (!is.null(new_conn) && DBI::dbIsValid(new_conn)) {
      # Reconnect via .reconnect_tbl_duckdb to preserve lazy-query operations.
      if (!is.null(x@value) && inherits(x@value, "tbl_duckdb_connection")) {
        x@value <- .reconnect_tbl_duckdb(x@value, new_conn)
      }
    }
  }
  x
})

#' @rdname dbReconnect
#' @export
setMethod("dbReconnect", "DBIConnection", function(x) {
  .reconnect_conn(x)
})

#' @rdname dbReconnect
#' @export
setMethod("dbReconnect", "connConnection", function(x) {
  x@con <- dbReconnect(x@con)
  x
})