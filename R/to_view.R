#' Convert lazy table to named view
#' @param x [`tbl_dbi`] \cr
#' \code{Required}. Object to convert to a view
#' @param name `character` \cr
#' \code{Required}. Name to assign view within database. Auto-generated if none
#' provided with prefix `"tmp_view_"`
#' @param temporary `logical` \cr 
#' If TRUE (default), the view will be deleted after the session ends
#' @param overwrite `logical` \cr
#' If TRUE (default), the view will overwrite an existing view
#' @param ... Additional arguments passed to [`DBI::dbExecute`]
#' @concept dbData
setGeneric("to_view", function(x, name, temporary = TRUE, overwrite = TRUE, ...) standardGeneric("to_view"))

#' @noRd
#' @export
setMethod(
  'to_view',
  signature(x = 'tbl_duckdb_connection'),
  function(x, name, temporary = TRUE, ...) {
    # TODO control for lazy tables versus computed tables (assume all lazy tables)
    # TODO support separate schema writing
    con <- dbplyr::remote_con(x)
    sql <- dbplyr::sql_render(x)
    if (missing(name)) {
      name <- unique_table_name("tmp_view")
    }
    
    sql_view <- glue::glue("CREATE OR REPLACE TEMPORARY VIEW '{name}' AS {sql}")
    
    if (!temporary) {
      sql_view <- gsub("TEMPORARY", "", sql_view)
    }
    
    if (!overwrite) {
      sql_view <- gsub("OR REPLACE ", "", sql_view)
    }
    
    invisible(DBI::dbExecute(con, sql_view, ...))
    
    res <- dplyr::tbl(con, name)
    
    return(res)
    
  }
)