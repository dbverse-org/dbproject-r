skip_if_not_installed("duckdb")

# Helper: create a file-backed dbData object
make_dbdata <- function() {
  db_path <- tempfile(fileext = ".duckdb")
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path)
  DBI::dbExecute(con, "CREATE TABLE test AS SELECT 1 as x")
  
  setClass("TestDbData", contains = "dbData", where = .GlobalEnv)
  new("TestDbData", value = dplyr::tbl(con, "test"))
}

test_that("conn() returns valid connection", {
  obj <- make_dbdata()
  expect_true(DBI::dbIsValid(conn(obj)))
  DBI::dbDisconnect(conn(obj))
})

test_that("[] auto-reconnects after disconnect", {
  obj <- make_dbdata()
  con <- conn(obj)
  
  DBI::dbDisconnect(con, shutdown = TRUE)
  expect_false(DBI::dbIsValid(con))
  
  # Should reconnect automatically
  expect_no_error(obj[])
  expect_true(DBI::dbIsValid(conn(obj)))
  
  DBI::dbDisconnect(conn(obj))
})

test_that("dbReconnect restores invalid connection", {
  obj <- make_dbdata()
  DBI::dbDisconnect(conn(obj), shutdown = TRUE)
  
  obj <- dbReconnect(obj)
  expect_true(DBI::dbIsValid(conn(obj)))
  
  DBI::dbDisconnect(conn(obj))
})

test_that("dbReconnect returns object with reconnected tbl", {
  obj <- make_dbdata()
  stale_con <- dbplyr::remote_con(obj@value)
  DBI::dbDisconnect(stale_con, shutdown = TRUE)
  expect_false(DBI::dbIsValid(stale_con))

  obj <- dbReconnect(obj)
  refreshed_con <- dbplyr::remote_con(obj@value)

  expect_true(DBI::dbIsValid(refreshed_con))
  expect_false(identical(stale_con, refreshed_con))

  DBI::dbDisconnect(refreshed_con)
})
