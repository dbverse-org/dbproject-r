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
#' @param ... Additional arguments passed to [`pins::pin_write()`]
#'
#' @return Invisibly returns the input object
#' @export
#' @method write_pin_conn dbMatrix
write_pin_conn.dbMatrix <- function(x, board, ...) {
  # Get dbdir from the incoming matrix's tbl
  incoming_dbdir <- x@value$src$con@driver@dbdir
  
  # Try to read the cached connection
  cached_conn <- tryCatch({
    connections::connection_pin_read(board, "cachedConnection")
  }, error = function(e) NULL)
  
  # If cached connection exists and dbdir matches, use its ID
  if (!is.null(cached_conn) && cached_conn@con@driver@dbdir == incoming_dbdir) {
    conn_id <- cached_conn@id
  } else {
    #TODO ATTACH incoming_dbdir, copy over the tbl OR create a new connection/conn_id
    stop("No matching connection found for this database")
  }
  
  # Write the lazy table to the pins board
  x@value <- to_view(
    x = x@value,
    temporary = FALSE,
    overwrite = TRUE,
    ...
  )
  
  # Get connection info using the matched ID
  session <- connections:::conn_session_get(conn_id)
  con <- structure(session, class = "conn_open")
  
  # Get SQL query instead of storing full table
  sql_query <- dbplyr::sql_render(x@value)
  
  metadata <- list(
    host = con$host,
    type = con$type,
    columns = lapply(dplyr::collect(head(x@value, 10)), class),
    matrix_info = list(
      dim_names = x@dim_names,
      dims = x@dims,
      matrix_class = class(x)[1]
    )
  )
  
  pin_obj <- structure(
    list(
      con = con,
      sql = sql_query,  # Store SQL instead of tbl
      dim_names = x@dim_names,
      dims = x@dims,
      matrix_class = class(x)[1]
    ),
    class = c("conn_matrix_table", "conn_table")
  )
  
  pins::pin_write(
    x = pin_obj,
    board = board,
    type = "rds",
    metadata = metadata,
    title = "dbMatrix pinned object",
    ...
  )
  invisible()
}

#' @method read_pin_conn conn_matrix_table
read_pin_conn.conn_matrix_table <- function(x) {
  tryCatch({
    # Get fresh connection
    con <- connections:::dbi_run_code(x$con)
    
    # Check if table exists
    db_objects <- DBI::dbGetQuery(con@con, 
                                  "SELECT table_name 
       FROM information_schema.tables 
       WHERE table_type IN ('BASE TABLE', 'VIEW')")$table_name
    table_name <- gsub(".*FROM\\s+([^ ]+).*", "\\1", x$sql)
    
    if (!table_name %in% db_objects) {
      cli::cli_abort(
        "Failed to read dbMatrix pin: table {.val {table_name}} not found in database. The table may be temporary or have been dropped."
      )
    }
    
    # Create table reference with error handling
    tbl_read <- tryCatch({
      dplyr::tbl(con@con, dbplyr::sql(x$sql))
    }, error = function(e) {
      cli::cli_abort(
        "Failed to read dbMatrix pin: {e$message}"
      )
    })
    
    # Add connection ID if it exists
    if (!is.null(attr(x$tbl, "conn_id"))) {
      attr(tbl_read, "conn_id") <- attr(x$tbl, "conn_id")
      class(tbl_read) <- c("tbl_conn", class(tbl_read))
    }
    
    # Create matrix object
    new(x$matrix_class,
        value = tbl_read,
        dim_names = x$dim_names,
        dims = x$dims,
        init = TRUE)
  }, error = function(e) {
    cli::cli_abort("{e$message}")
  })
}

