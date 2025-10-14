#' Convert lazy table to named VIEW
#' @param x `tbl_sql`
#'   **Required**. `tbl_sql` object to convert to a VIEW.
#' @param name `character`
#'   **Required**. Name to assign VIEW within database. Auto-generated if none
#'   provided with prefix `"tmp_view_"`
#' @param temporary `logical`
#'   If `TRUE` (default), the VIEW will not be saved in the database
#' @param overwrite `logical`
#'   If `TRUE` (default), the VIEW will overwrite an existing VIEW of the same name
#' @param ... Additional arguments passed to [DBI::dbExecute()]
#' @concept dbData
#' @export
setMethod(
  'to_view',
  signature(x = 'ANY'),
  function(x, name, temporary = TRUE, overwrite = TRUE, ...) {
    # Ensure the object has remote_con and sql_render methods available
    if (!inherits(x, c("tbl_sql", "tbl_dbi", "tbl_lazy"))) {
      stop("Object must be a database table (tbl_sql, tbl_dbi, or tbl_lazy)")
    }
    con <- dbplyr::remote_con(x)
    sql <- dbplyr::sql_render(x)

    # Generate name if not provided
    if (missing(name)) {
      name <- .unique_table_name("_tmp_view")
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
