#' Write a dbSpatial object to a pins board
#'
#' @param x A dbSpatial object
#' @param board A pins board object
#' @param name Name for the pin
#' @param ... Additional arguments passed to pins::pin_write
#' @return Invisibly returns the input object
#' @export
#' @method write_pin_conn dbSpatial
write_pin_conn.dbSpatial <- function(x, board, name, ...) {
  # Always materialize to a permanent table using the pin name so the
  # pinned spatial object survives connection/session teardown.
  permanent_name <- paste0("pin_", gsub("[^a-zA-Z0-9_]", "_", name))
  new_tbl <- dplyr::compute(
    x@value,
    name = permanent_name,
    temporary = FALSE,
    overwrite = TRUE
  )

  x <- methods::new(
    "dbSpatial",
    value = new_tbl,
    name = permanent_name
  )

  con <- dbplyr::remote_con(x@value)
  dbdir <- tryCatch(con@driver@dbdir, error = function(e) NA)
  table_name <- x@name

  metadata <- list(
    host = NA,
    type = "dbSpatial",
    columns = lapply(dplyr::collect(utils::head(x@value, 10)), class),
    dbdir = dbdir
  )

  pin_obj <- structure(
    list(
      con = list(dbdir = dbdir),
      table_name = table_name,
      spatial_class = "dbSpatial"
    ),
    class = c("conn_spatial_table", "conn_table")
  )

  pins::pin_write(
    x = pin_obj,
    board = board,
    name = name,
    type = "rds",
    metadata = metadata,
    ...
  )

  return(invisible(x))
}

#' Read a pinned dbSpatial object from a pins board
#'
#' @param x A pinned conn_spatial_table object
#' @return A dbSpatial object
#' @method read_pin_conn conn_spatial_table
#' @export
read_pin_conn.conn_spatial_table <- function(x) {
  dbdir <- x$con$dbdir
  if (is.null(dbdir) || is.na(dbdir)) {
    cli::cli_abort("No database path found in pinned object metadata.")
  }

  con <- .connect_duckdb_lock_safe(dbdir = dbdir)

  table_name <- x$table_name
  if (is.null(table_name) || is.na(table_name)) {
    cli::cli_abort("No table name found in pinned object metadata.")
  }

  # Check if table exists
  db_tables <- DBI::dbListTables(con)
  if (!table_name %in% db_tables) {
    cli::cli_abort(
      "Table {.val {table_name}} not found in database."
    )
  }

  new_tbl <- dplyr::tbl(con, table_name)
  db_spatial <- methods::new(
    "dbSpatial",
    value = new_tbl,
    name = table_name
  )

  return(db_spatial)
}
