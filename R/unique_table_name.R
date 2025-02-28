#' Generate table names
#' @details
#' based on dbplyr::unique_table_name
#'
#' @noRd
#' @keywords internal
unique_table_name <- function(prefix = "dbData"){
  vals <- c(letters, LETTERS, 0:9)
  name <- paste0(sample(vals, 10, replace = TRUE), collapse = "")
  paste0(prefix, "_", name)
}