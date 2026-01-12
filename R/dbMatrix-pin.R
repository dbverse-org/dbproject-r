#' Write Pin Connection Generic
#'
#' @description Generic function for writing connection objects to a pins board
#'
#' @param x Object to write
#' @param board A pins board object
#' @param ... Additional arguments passed to methods
#'
#' @export
write_pin_conn <- function(x, board, ...) {
  UseMethod("write_pin_conn")
}

#' Read a pinned dbMatrix object from a board
#' @param board A pins board object
#' @param name The name of the pin
#' @param version The version of the pin to get (optional)
#' @returns A dbMatrix object (dbSparseMatrix or dbDenseMatrix)
#' @export
connection_pin_read <- function(board, name, version = NULL) {
  pinned <- pins::pin_read(board = board, name = name, version = version)
  read_pin_conn(pinned)
}

#' Read Pin Connection Generic
#'
#' @description Generic function for reading connection objects from a pins board
#'
#' @param x A pinned connection object
#'
#' @export
read_pin_conn <- function(x) {
  UseMethod("read_pin_conn")
}

#' Write a dbMatrix object to a pins board
#'
#' @description S3 method for writing dbMatrix objects to a pins board while maintaining
#' connection state and metadata consistent with the connections package.
#'
#' @param x A [`dbMatrix`] object (dbSparseMatrix or dbDenseMatrix)
#' @param board A pins [`board_folder`] object
#' @param name Name for the pin (required)
#' @param ... Additional arguments passed to [`pins::pin_write()`]
#'
#' @return Invisibly returns the input object
#' @export
#' @method write_pin_conn dbMatrix
write_pin_conn.dbMatrix <- function(x, board, name, ...) {
  con <- dbplyr::remote_con(x@value)
  incoming_dbdir <- tryCatch(con@driver@dbdir, error = function(e) NA)
  
  # STEP 1: Always materialize to a PERMANENT table using the pin name
  # This ensures data persists across sessions even if original was temporary
  # Use the pin name as the permanent table name to avoid conflicts
  permanent_name <- paste0("pin_", gsub("[^a-zA-Z0-9_]", "_", name))
  
  # Use dplyr::compute which dispatches to dbMatrix's compute.dbSparseMatrix method
  # This properly handles: dimnames persistence and  temp table cleanup
  x <- dplyr::compute(
    x,
    name = permanent_name,
    temporary = FALSE,
    dimnames = TRUE,
    overwrite = TRUE
  )
  table_name <- x@name

  # STEP 2: Pin metadata (ACID-compliant via pins board)
  dbdir <- incoming_dbdir

  metadata <- list(
    host = NA,
    type = "dbMatrix",
	columns = lapply(dplyr::collect(utils::head(x@value, 10)), class),
    matrix_info = list(
      dim_names = x@dim_names,
      dims = x@dims,
      matrix_class = class(x)[1]
    ),
    dbdir = dbdir
  )

  pin_obj <- structure(
    list(
      con = list(dbdir = dbdir),
      table_name = table_name,
      dim_names = x@dim_names,
      dims = x@dims,
      matrix_class = class(x)[1]
    ),
    class = c("conn_matrix_table", "conn_table")
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

#' @method write_pin_conn tbl_duckdb_connection
#' @export
write_pin_conn.tbl_duckdb_connection <- function(x, board, ...) {
  sql_query <- dbplyr::sql_render(x)
  table_name <- tryCatch(dbplyr::remote_name(x), error = function(e) NULL)
  con <- tryCatch(dbplyr::remote_con(x), error = function(e) NULL)
  dbdir <- tryCatch(con@driver@dbdir, error = function(e) NA)
  metadata <- list(
    host = NA,
    type = "duckdb",
	columns = lapply(dplyr::collect(utils::head(x, 10)), class),
    matrix_info = list(
      dim_names = NULL,
      dims = NULL,
      matrix_class = "tbl_duckdb_connection"
    ),
    dbdir = dbdir
  )
  pin_obj <- structure(
    list(
      con = list(dbdir = dbdir),
      table_name = table_name,
      sql = sql_query,
      dim_names = NULL,
      dims = NULL,
      matrix_class = "tbl_duckdb_connection"
    ),
    class = c("conn_matrix_table", "conn_table")
  )
  pins::pin_write(
    x = pin_obj,
    board = board,
    type = "rds",
    metadata = metadata,
    ...
  )

  return(invisible())
}

#' @method write_pin_conn tbl_sql
#' @export
write_pin_conn.tbl_sql <- function(x, board, ...) {
  sql_query <- dbplyr::sql_render(x)
  table_name <- tryCatch(dbplyr::remote_name(x), error = function(e) NULL)
  con <- dbplyr::remote_con(x)
  dbdir <- tryCatch(con@driver@dbdir, error = function(e) NA)

  metadata <- list(
    host = NA,
    type = "sql",
	columns = lapply(dplyr::collect(utils::head(x, 10)), class),
    matrix_info = list(dim_names = NULL, dims = NULL, matrix_class = "tbl_sql"),
    dbdir = dbdir
  )

  pin_obj <- structure(
    list(
      con = list(dbdir = dbdir),
      table_name = table_name,
      sql = sql_query,
      dim_names = NULL,
      dims = NULL,
      matrix_class = "tbl_sql"
    ),
    class = c("conn_matrix_table", "conn_table")
  )

  pins::pin_write(
    x = pin_obj,
    board = board,
    type = "rds",
    metadata = metadata,
    ...
  )
  
  return(invisible())
}

#' @method write_pin_conn tbl_lazy
#' @export
write_pin_conn.tbl_lazy <- function(x, board, ...) {
  sql_query <- dbplyr::sql_render(x)
  table_name <- tryCatch(dbplyr::remote_name(x), error = function(e) NULL)
  con <- dbplyr::remote_con(x)
  dbdir <- tryCatch(con@driver@dbdir, error = function(e) NA)

  metadata <- list(
    host = NA,
    type = "lazy",
	columns = lapply(dplyr::collect(utils::head(x, 10)), class),
    matrix_info = list(
      dim_names = NULL,
      dims = NULL,
      matrix_class = "tbl_lazy"
    ),
    dbdir = dbdir
  )

  pin_obj <- structure(
    list(
      con = list(dbdir = dbdir),
      table_name = table_name,
      sql = sql_query,
      dim_names = NULL,
      dims = NULL,
      matrix_class = "tbl_lazy"
    ),
    class = c("conn_matrix_table", "conn_table")
  )

  pins::pin_write(
    x = pin_obj,
    board = board,
    type = "rds",
    metadata = metadata,
    ...
  )
  
  return(invisible())
}

#' @method write_pin_conn tbl
#' @export
write_pin_conn.tbl <- function(x, board, ...) {
  sql_query <- dbplyr::sql_render(x)
  table_name <- tryCatch(dbplyr::remote_name(x), error = function(e) NULL)
  con <- tryCatch(dbplyr::remote_con(x), error = function(e) NULL)
  dbdir <- tryCatch(con@driver@dbdir, error = function(e) NA)

  metadata <- list(
    host = NA,
    type = "tbl",
	columns = lapply(dplyr::collect(utils::head(x, 10)), class),
    matrix_info = list(dim_names = NULL, dims = NULL, matrix_class = "tbl"),
    dbdir = dbdir
  )

  pin_obj <- structure(
    list(
      con = list(dbdir = dbdir),
      table_name = table_name,
      sql = sql_query,
      dim_names = NULL,
      dims = NULL,
      matrix_class = "tbl"
    ),
    class = c("conn_matrix_table", "conn_table")
  )

  pins::pin_write(
    x = pin_obj,
    board = board,
    type = "rds",
    metadata = metadata,
    ...
  )

  return(invisible())
}

#' Read a pinned dbMatrix from pins board
#'
#' @description S3 method for reading dbMatrix objects from a pins board.
#' Reconstructs the full dbMatrix object.
#'
#' @param x A pinned conn_matrix_table object
#' @return A dbMatrix object (dbSparseMatrix or dbDenseMatrix)
#' @method read_pin_conn conn_matrix_table
#' @export
read_pin_conn.conn_matrix_table <- function(x) {
  # Reconnect using dbdir if available
  dbdir <- x$con$dbdir
  if (is.null(dbdir) || is.na(dbdir)) {
    cli::cli_abort("No database path found in pinned object metadata.")
  }
  drv <- duckdb::duckdb(dbdir = dbdir)
  con <- DBI::dbConnect(drv)

  table_name <- x$table_name
  if (is.null(table_name) || is.na(table_name)) {
    table_name <- NULL
  }

  db_objects <- NULL
  if (!is.null(table_name)) {
    db_objects <- DBI::dbGetQuery(
      con,
      "SELECT table_name FROM information_schema.tables WHERE table_type IN ('BASE TABLE', 'VIEW')"
    )$table_name

    if (!table_name %in% db_objects) {
      # Legacy cleanup: sometimes SQL-derived names can come through as "(tbl)".
      stripped <- gsub("^\\((.*)\\)$", "\\1", table_name)
      if (!identical(stripped, table_name) && stripped %in% db_objects) {
        table_name <- stripped
      } else {
        cli::cli_abort(
          "Failed to read dbMatrix pin: table {.val {table_name}} not found in database. The table may be temporary or have been dropped."
        )
      }
    }
  }

  # Check if this is a dbMatrix pin (has matrix_class)
  if (!is.null(x$matrix_class) && x$matrix_class %in% c("dbSparseMatrix", "dbDenseMatrix")) {
    if (is.null(table_name)) {
      # Legacy: parse from SQL if needed
      table_name <- gsub(".*FROM\\s+([^ ]+).*", "\\1", x$sql)
      if (!is.null(db_objects)) {
        stripped <- gsub("^\\((.*)\\)$", "\\1", table_name)
        if (!identical(stripped, table_name) && stripped %in% db_objects) {
          table_name <- stripped
        }
      }
    }

    # Reconstruct full dbMatrix object
    new_tbl <- dplyr::tbl(con, table_name)

    # Create new dbMatrix
    db_mat <- methods::new(
      x$matrix_class,
      value = new_tbl,
      name = table_name,
      dims = x$dims,
      dim_names = x$dim_names,
      init = TRUE
    )

    return(db_mat)
  }

  # Non-matrix pins: prefer direct table reference when available; otherwise fall back to stored SQL.
  if (!is.null(table_name)) {
    return(dplyr::tbl(con, table_name))
  }

  sql_query <- x$sql
  if (!is.null(sql_query) && !is.na(sql_query)) {
    return(dplyr::tbl(con, dbplyr::sql(sql_query)))
  }

  cli::cli_abort("Pinned object is missing both table_name and sql.")
}

