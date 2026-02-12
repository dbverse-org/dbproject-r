#' dbProject: database connection and table management
#'
#' @description
#' R6 class for managing DuckDB connections and pinning lazy database tables.
#' Wraps a [pins::board_folder()] with a cached connection object stored as
#' "cachedConnection" for automatic reconnection.
#'
#' @export
dbProject <- R6::R6Class(
  "dbProject",
  public = list(
    #' @description
    #' Create a new dbProject object.
    #'
    #' @param path A character string specifying the folder path for pins.
    #' @param ... Additional arguments passed to [connections::connection_open()]
    initialize = function(path, ...) {
      if (is.null(path) || !is.character(path) || length(path) != 1) {
        stop("'path' must be a single character string")
      }

      private$path <- path
      private$board <- pins::board_folder(path, versioned = TRUE)

      # Resolve dbdir parameter to ensure absolute path
      dots <- list(...)
      dbdir_val <- NULL
      if ("dbdir" %in% names(dots) && !is.null(dots$dbdir)) {
        dbdir_val <- .resolve_dbdir(dots$dbdir)
      }

      tryCatch(
        {
          # Use bquote with .() to force evaluation of dbdir value
          # This ensures connections::connection_open captures the actual path
          # instead of a variable name (which would fail during pin restoration)
          if (!is.null(dbdir_val)) {
            private$conn_ <- eval(bquote(
              connections::connection_open(
                drv = duckdb::duckdb(),
                dbdir = .(dbdir_val)
              )
            ))
          } else {
            # In-memory database
            private$conn_ <- connections::connection_open(
              drv = duckdb::duckdb()
            )
          }
          connections::connection_pin_write(
            board = private$board,
            x = private$conn_,
            name = "cachedConnection",
            title = "connConnection pinned object"
          )

          # Write the board manifest to the project
          pins::write_board_manifest(private$board)
        },
        error = function(e) {
          stop("Failed to establish database connection: ", e$message)
        }
      )

      invisible(self)
    },

    #' @description
    #' Close the current connection, if any.
    disconnect = function() {
      if (!is.null(private$conn_)) {
        connections::connection_close(private$conn_)
        private$conn_ <- NULL
      }
      invisible(self)
    },

    #' @description
    #' Reconnect to the database in the project.
    reconnect = function() {
      if (!is.null(private$board)) {
        private$conn_ <- connections::connection_pin_read(
          board = private$board,
          name = "cachedConnection"
        )
      }
      invisible(self)
    },

    #' @description
    #' Update the project's cached DuckDB database path.
    #'
    #' @details
    #' Overwrites the "cachedConnection" pin with a connection that uses the
    #' provided `dbdir`. Uses forced evaluation to avoid pins restoring a
    #' connection that references an out-of-scope variable.
    #'
    #' @param dbdir Path to the DuckDB database file.
    set_dbdir = function(dbdir) {
      if (is.null(private$board)) {
        stop("Board is not available")
      }
      if (is.null(dbdir) || !is.character(dbdir) || length(dbdir) != 1) {
        stop("'dbdir' must be a single character string")
      }

      dbdir_val <- .resolve_dbdir(dbdir)

      # Ensure the stored connection spec captures the literal path.
      private$conn_ <- eval(bquote(
        connections::connection_open(
          drv = duckdb::duckdb(),
          dbdir = .(dbdir_val)
        )
      ))

      connections::connection_pin_write(
        board = private$board,
        x = private$conn_,
        name = "cachedConnection",
        title = "connConnection pinned object"
      )
      pins::write_board_manifest(private$board)
      invisible(self)
    },

    #' @description
    #' Retrieve the DBI connection from the project, reconnecting if necessary.
    #' @return A `DBIConnection` object for direct database operations.
    #' @seealso [conn()] S4 generic for dbData objects
    get_conn = function() {
      if (is.null(private$conn_) || !DBI::dbIsValid(private$conn_@con)) {
        if (private$has_cached_connection()) {
          self$reconnect()
        } else {
          stop("No active or cached connection available")
        }
      }
      private$conn_@con
    },

    #' @description
    #' Return the [pins::board_folder()] object used by the project.
    #' @return The [pins::board_folder()] object.
    get_board = function() {
      private$board
    },

    #' @description
    #' Write a lazy database tbl to the project.
    #'
    #' @param x A [`tbl`] object to be written to the board.
    #' @param name A character string specifying the name of the pin.
    #' @return The materialized object (for dbMatrix/dbSpatial) pointing to permanent table,
    #'   or invisibly returns the dbProject object for other types.
    pin_write = function(x, name) {
      if (is.null(private$board)) {
        stop("Board is not available")
      }
      if (missing(name) || !is.character(name) || length(name) != 1) {
        stop("'name' must be a single character string")
      }
      
      # Use write_pin_conn for dbMatrix, dbSpatial, or tbl objects
      # This enables proper S3 method dispatch
      # IMPORTANT: write_pin_conn returns the materialized object for dbMatrix/dbSpatial
      # We return this to prevent stale references to cleaned-up temp tables
      result <- write_pin_conn(x = x, board = private$board, name = name)
      
      pins::write_board_manifest(private$board)
      
      # Return the materialized object (or invisible self for non-matrix types)
      if (inherits(x, c("dbMatrix", "dbSparseMatrix", "dbDenseMatrix", "dbSpatial"))) {
        return(result)
      } else {
        return(invisible(self))
      }
    },

    #' @description
    #' Delete a pin from the project.
    #'
    #' @param name A character string specifying the name of the pin to delete.
    #' @param ... Additional arguments passed to [pins::pin_delete()].
    #' @return Invisibly returns the dbProject object for method chaining.
    pin_delete = function(name, ...) {
      if (is.null(private$board)) {
        stop("Board is not available")
      }
      if (missing(name) || !is.character(name) || length(name) != 1) {
        stop("'name' must be a single character string")
      }
      pins::pin_delete(board = private$board, name = name, ...)
      pins::write_board_manifest(private$board)
      invisible(self)
    },

    #' @description
    #' Read a pinned object from the project's board.
    #'
    #' @param name A character string specifying the name of the pin.
    #' @return The object stored in the specified pin.
    pin_read = function(name) {
      if (is.null(private$board)) {
        stop("Board is not available")
      }
      if (missing(name) || !is.character(name) || length(name) != 1) {
        stop("'name' must be a single character string")
      }
      if (identical(name, "cachedConnection")) {
        return(connections::connection_pin_read(board = private$board, name = "cachedConnection"))
      }

      pinned <- pins::pin_read(board = private$board, name = name)
      if (!inherits(pinned, "conn_table")) {
        return(pinned)
      }

      con <- self$get_conn()

      if (inherits(pinned, "conn_matrix_table")) {
        table_name <- pinned$table_name %||% NA_character_
        if (is.na(table_name) || !nzchar(table_name)) {
          table_name <- NULL
        }

        if (!is.null(pinned$matrix_class) && pinned$matrix_class %in% c("dbSparseMatrix", "dbDenseMatrix")) {
          if (is.null(table_name)) {
            cli::cli_abort("Pinned dbMatrix is missing table_name.")
          }
          new_tbl <- dplyr::tbl(con, table_name)
          return(methods::new(
            pinned$matrix_class,
            value = new_tbl,
            name = table_name,
            dims = pinned$dims,
            dim_names = pinned$dim_names,
            init = TRUE
          ))
        }

        if (!is.null(table_name)) {
          return(dplyr::tbl(con, table_name))
        }

        sql_query <- pinned$sql
        if (!is.null(sql_query) && !is.na(sql_query)) {
          return(dplyr::tbl(con, dbplyr::sql(sql_query)))
        }

        cli::cli_abort("Pinned object is missing both table_name and sql.")
      }

      if (inherits(pinned, "conn_spatial_table")) {
        table_name <- pinned$table_name
        if (is.null(table_name) || is.na(table_name)) {
          cli::cli_abort("No table name found in pinned object metadata.")
        }

        new_tbl <- dplyr::tbl(con, table_name)
        return(methods::new(
          "dbSpatial",
          value = new_tbl,
          name = table_name
        ))
      }

      # Unknown conn_table type: fall back to returning the pin payload.
      pinned
    },

    #' @description
    #' Restore all pins from the board manifest.
    #'
    #' @details
    #' Reads the board manifest and restores the cached connection and all
    #' pinned objects. The connection is restored internally, while other
    #' pinned objects are returned as a named list for the user to assign.
    #'
    #' @return A named list of restored pinned objects (excluding the connection).
    #' @examples
    #' \dontrun{
    #' # Restore and assign objects
    #' objs <- proj$restore()
    #' my_matrix <- objs$my_matrix
    #' my_spatial <- objs$my_spatial
    #' }
    restore = function() {
      manifest_path <- file.path(private$path, "_pins.yaml")
      if (!file.exists(manifest_path)) {
        stop("No manifest file found")
      }

      manifest <- yaml::read_yaml(manifest_path)
      restored <- list()

      for (pin_name in names(manifest)) {
        if (pin_name == "cachedConnection") {
          # Restore connection internally
          private$conn_ <- connections::connection_pin_read(
            board = private$board,
            name = "cachedConnection"
          )
        } else {
          # Add to return list for user to assign
          restored[[pin_name]] <- self$pin_read(pin_name)
        }
      }

      return(restored)
    },

    #' @description
    #' Remove a table from the connected database
    #'
    #' @param name A character string specifying the name of the table to remove
    #' @return Invisibly returns the dbProject object for method chaining
    dbRemoveTable = function(name) {
      if (is.null(private$conn_)) {
        stop("No active connection available")
      }
      DBI::dbRemoveTable(private$conn_@con, name)
      invisible(self)
    },

    #' @description
    #' Remove a view from the connected database
    #'
    #' @param name A character string specifying the name of the table to remove
    #' @return Invisibly returns the dbProject object for method chaining
    dbRemoveView = function(name) {
      if (is.null(private$conn_)) {
        stop("No active connection available")
      }
      sql <- glue::glue("DROP VIEW IF EXISTS {name}")
      DBI::dbExecute(private$conn_@con, sql)
      invisible(self)
    },

    #' @description
    #' Print summary information, including connection status, path, and board details.
    #'
    #' @param ... Unused arguments (for consistency with generic print method)
    print = function(...) {
      cli::cli_rule(center = "dbProject")

      if (!is.null(private$conn_)) {
        dbdir <- private$conn_@con@driver@dbdir

        # Handle in-memory connections
        if (dbdir == ":memory:") {
          if (DBI::dbIsValid(private$conn_@con)) {
            cli::cli_alert_success("Connected")
          } else {
            cli::cli_alert_danger("Disconnected")
          }
        } else if (file.exists(dbdir)) {
          # Handle file-based connections
          if (DBI::dbIsValid(private$conn_@con)) {
            cli::cli_alert_success("Connected")
          } else {
            cli::cli_alert_danger("Disconnected")
          }
        } else {
          cli::cli_alert_danger("Invalid Connection (file missing)")
        }
      } else {
        cli::cli_alert_danger("Disconnected")
      }

      # Board Content section
      cli::cli_rule("Board Content")
      if (dir.exists(private$path)) {
        cli::cli_text("Board Path: {.path {normalizePath(private$path)}}")
      } else {
        cli::cli_alert_danger(
          "Board Path: {.path {private$path}} (directory not found)"
        )
      }

      board_items <- tryCatch(
        {
          pins::pin_search(private$board)
        },
        error = function(e) {
          # cli::cli_alert_danger("Board not found")
          return(NULL)
        }
      )
      if (!is.null(board_items) && nrow(board_items) > 0) {
        print(board_items)
      }

      # Database Content section
      cli::cli_rule("Database Content")
      if (!is.null(private$conn_)) {
        dbdir <- private$conn_@con@driver@dbdir
        cli::cli_text("Database Path: {.path {dbdir}}")

        if (!file.exists(dbdir) && dbdir != ":memory:") {
          cli::cli_alert_danger("Database file not found")
        } else if (DBI::dbIsValid(private$conn_@con)) {
          tryCatch(
            {
              # Query to get table types including temporary tables and views
              query <- "SELECT table_name, table_type FROM information_schema.tables"
              table_types <- DBI::dbGetQuery(private$conn_@con, query)

              # Categorize tables
              tables <- table_types[table_types$table_type == "BASE TABLE", , drop = FALSE]
              views <- table_types[grepl("VIEW", table_types$table_type, ignore.case = TRUE), , drop = FALSE]
              temp_tables <- table_types[grepl("TEMPORARY", table_types$table_type, ignore.case = TRUE), , drop = FALSE]

              # Print categories using cli
              if (nrow(tables) > 0) {
                cli::cli_alert_info("Tables:")
                cli::cli_ul(tables$table_name)
              }

              if (nrow(temp_tables) > 0) {
                cli::cli_alert_info("Temporary Tables:")
                cli::cli_ul(temp_tables$table_name)
              }

              if (nrow(views) > 0) {
                cli::cli_alert_info("Views:")
                cli::cli_ul(views$table_name)
              }
            },
            error = function(e) {
              cli::cli_alert_warning(
                "Unable to retrieve table information: {e$message}"
              )
            }
          )
        } else {
          cli::cli_alert_info("No active connection.")
        }
      } else {
        cli::cli_alert_info("No active connection.")
      }
      invisible(self)
    },

    #' @description
    #' Check if there is an active database connection.
    #' @return A logical value indicating whether the project has an active connection.
    is_connected = function() {
      !is.null(private$conn_) && DBI::dbIsValid(private$conn_@con)
    }
  ),

  private = list(
    conn_ = NULL,
    board = NULL,
    path = NULL,

    has_cached_connection = function() {
      "cachedConnection" %in% pins::pin_list(private$board)
    }
  )
)
