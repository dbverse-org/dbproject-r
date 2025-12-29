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

      # Resolve dbdir parameter to prevent connections expression capture
      dots <- list(...)
      if ("dbdir" %in% names(dots) && !is.null(dots$dbdir)) {
        dots$dbdir <- .resolve_dbdir(dots$dbdir)
      }

      tryCatch(
        {
          private$conn <- do.call(
            connections::connection_open,
            c(list(drv = duckdb::duckdb()), dots)
          )
          connections::connection_pin_write(
            board = private$board,
            x = private$conn,
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
      if (!is.null(private$conn)) {
        connections::connection_close(private$conn)
        private$conn <- NULL
      }
      invisible(self)
    },

    #' @description
    #' Reconnect to the database in the project.
    reconnect = function() {
      if (!is.null(private$board)) {
        private$conn <- connections::connection_pin_read(
          board = private$board,
          name = "cachedConnection"
        )
      }
      invisible(self)
    },

    #' @description
    #' Retrieve the connection from the project, reconnecting if necessary.
    #' @return A `connConnection` object created from [`connections::connection_open`]
    get_connection = function() {
      if (is.null(private$conn)) {
        if (private$has_cached_connection()) {
          self$reconnect()
        } else {
          stop("No active or cached connection available")
        }
      }
      private$conn
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
    #' @return Invisibly returns the dbProject object for method chaining.
    pin_write = function(x, name) {
      if (is.null(private$board)) {
        stop("Board is not available")
      }
      if (missing(name) || !is.character(name) || length(name) != 1) {
        stop("'name' must be a single character string")
      }
      connections::connection_pin_write(
        board = private$board,
        x = x,
        name = name,
        title = "dbProject pinned object",
        versioned = TRUE
      )
      pins::write_board_manifest(private$board)
      invisible(self)
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
      connections::connection_pin_read(
        board = private$board,
        name = name
      )
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
          private$conn <- connections::connection_pin_read(
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
      if (is.null(private$conn)) {
        stop("No active connection available")
      }
      DBI::dbRemoveTable(private$conn@con, name)
      invisible(self)
    },

    #' @description
    #' Remove a view from the connected database
    #'
    #' @param name A character string specifying the name of the table to remove
    #' @return Invisibly returns the dbProject object for method chaining
    dbRemoveView = function(name) {
      if (is.null(private$conn)) {
        stop("No active connection available")
      }
      sql <- glue::glue("DROP VIEW IF EXISTS {name}")
      DBI::dbExecute(private$conn@con, sql)
      invisible(self)
    },

    #' @description
    #' Print summary information, including connection status, path, and board details.
    #'
    #' @param ... Unused arguments (for consistency with generic print method)
    print = function(...) {
      cli::cli_rule(center = "dbProject")

      if (!is.null(private$conn)) {
        dbdir <- private$conn@con@driver@dbdir

        # Handle in-memory connections
        if (dbdir == ":memory:") {
          if (DBI::dbIsValid(private$conn@con)) {
            cli::cli_alert_success("Connected")
          } else {
            cli::cli_alert_danger("Disconnected")
          }
        } else if (file.exists(dbdir)) {
          # Handle file-based connections
          if (DBI::dbIsValid(private$conn@con)) {
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
      if (!is.null(private$conn)) {
        dbdir <- private$conn@con@driver@dbdir
        cli::cli_text("Database Path: {.path {dbdir}}")

        if (!file.exists(dbdir) && dbdir != ":memory:") {
          cli::cli_alert_danger("Database file not found")
        } else if (DBI::dbIsValid(private$conn@con)) {
          tryCatch(
            {
              # Query to get table types including temporary tables and views
              query <- "SELECT table_name, table_type FROM information_schema.tables"
              table_types <- DBI::dbGetQuery(private$conn@con, query)

              # Categorize tables
              tables <- dplyr::filter(table_types, table_type == 'BASE TABLE')
              views <- dplyr::filter(
                table_types,
                grepl("VIEW", table_type, ignore.case = TRUE)
              )
              temp_tables <- dplyr::filter(
                table_types,
                grepl("TEMPORARY", table_type, ignore.case = TRUE)
              )

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
      !is.null(private$conn) && DBI::dbIsValid(private$conn@con)
    }
  ),

  private = list(
    conn = NULL,
    board = NULL,
    path = NULL,

    has_cached_connection = function() {
      "cachedConnection" %in% pins::pin_list(private$board)
    }
  )
)
