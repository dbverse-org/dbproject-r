skip_on_cran()
skip_if_not_installed("duckdb")

# These tests ensure pinned dbMatrix/dbSpatial objects can be restored after the
# underlying DuckDB file moves, as long as the board's cachedConnection is updated.

.test_move_duckdb <- function(from, to) {
  ok <- file.rename(from, to)
  if (!isTRUE(ok)) {
    cli::cli_abort("Failed to move DuckDB database file")
  }
  invisible(TRUE)
}

test_that("dbMatrix pin read prefers cachedConnection after DB move", {
  skip_if_not_installed("dbMatrix")

  tmp_dir <- withr::local_tempdir()
  proj_dir <- file.path(tmp_dir, "project")
  db_path_old <- file.path(tmp_dir, "orig.duckdb")
  db_path_new <- file.path(tmp_dir, "moved.duckdb")

  proj <- dbProject$new(path = proj_dir, dbdir = db_path_old)
  board <- proj$get_board()

  # Create a small dbMatrix in the project DB and pin it.
  mat <- matrix(c(1, 0, 2, 0, 3, 4), nrow = 2, byrow = TRUE)
  dimnames(mat) <- list(c("r1", "r2"), c("c1", "c2", "c3"))

  dbmat <- dbMatrix::as.dbMatrix(
    x = mat,
    con = proj$get_conn(),
    name = "mat_tbl",
    overwrite = TRUE
  )
  proj$pin_write(dbmat, name = "pinned_mat")

  # Flush to disk before moving the file.
  DBI::dbExecute(proj$get_conn(), "CHECKPOINT")
  proj$disconnect()

  expect_true(file.exists(db_path_old))
  .test_move_duckdb(db_path_old, db_path_new)
  expect_false(file.exists(db_path_old))

  # Update cachedConnection to point at the new DB path.
  proj$set_dbdir(db_path_new)

  # Must restore via cachedConnection; the per-pin dbdir is now stale.
  restored <- proj$pin_read("pinned_mat")
  expect_true(inherits(restored, "dbMatrix"))
  con2 <- dbplyr::remote_con(restored@value)
  expect_true(DBI::dbIsValid(con2))
  expect_true(restored@name %in% DBI::dbListTables(con2))
  expect_false(file.exists(db_path_old))

  proj$disconnect()
})

test_that("conn_spatial_table pin read prefers cachedConnection after DB move", {
  skip_if_not_installed("dbSpatial")

  tmp_dir <- withr::local_tempdir()
  proj_dir <- file.path(tmp_dir, "project")
  db_path_old <- file.path(tmp_dir, "orig.duckdb")
  db_path_new <- file.path(tmp_dir, "moved.duckdb")

  proj <- dbProject$new(path = proj_dir, dbdir = db_path_old)
  board <- proj$get_board()

  # Create a simple table; dbSpatial-pin reader only requires that the table exists.
  DBI::dbWriteTable(
    conn = proj$get_conn(),
    name = "spatial_tbl",
    value = data.frame(x = 1:3, y = 4:6),
    overwrite = TRUE
  )
  DBI::dbExecute(proj$get_conn(), "CHECKPOINT")

  pin_obj <- structure(
    list(
      con = list(dbdir = db_path_old),
      table_name = "spatial_tbl",
      spatial_class = "dbSpatial"
    ),
    class = c("conn_spatial_table", "conn_table")
  )

  pins::pin_write(
    x = pin_obj,
    board = board,
    name = "pinned_spatial",
    type = "rds",
    metadata = list(
      host = NA,
      type = "dbSpatial",
      columns = lapply(data.frame(x = 1:3, y = 4:6), class),
      dbdir = db_path_old
    )
  )

  proj$disconnect()

  expect_true(file.exists(db_path_old))
  .test_move_duckdb(db_path_old, db_path_new)
  expect_false(file.exists(db_path_old))

  proj$set_dbdir(db_path_new)

  restored <- proj$pin_read("pinned_spatial")
  expect_true(inherits(restored, "dbSpatial"))
  expect_equal(restored@name, "spatial_tbl")
  expect_false(file.exists(db_path_old))

  proj$disconnect()
})

test_that("dbSpatial pinning materializes temporary tables", {
  skip_if_not_installed("dbSpatial")

  tmp_dir <- withr::local_tempdir()
  proj_dir <- file.path(tmp_dir, "project")
  db_path <- file.path(tmp_dir, "spatial.duckdb")

  proj <- dbProject$new(path = proj_dir, dbdir = db_path)
  con <- proj$get_conn()

  DBI::dbWriteTable(
    conn = con,
    name = "spatial_tmp",
    value = data.frame(x = 1:3, y = 4:6),
    temporary = TRUE,
    overwrite = TRUE
  )

  spatial_obj <- methods::new(
    "dbSpatial",
    value = dplyr::tbl(con, "spatial_tmp"),
    name = "spatial_tmp"
  )

  restored_obj <- proj$pin_write(spatial_obj, name = "pinned_spatial_temp")
  pinned <- pins::pin_read(proj$get_board(), "pinned_spatial_temp")

  expect_true(inherits(restored_obj, "dbSpatial"))
  expect_equal(pinned$table_name, "pin_pinned_spatial_temp")
  expect_true(DBI::dbExistsTable(con, pinned$table_name))

  proj$disconnect()
})
