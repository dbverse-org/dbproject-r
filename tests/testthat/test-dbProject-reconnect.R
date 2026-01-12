skip_on_cran()
skip_if_not_installed("duckdb")

test_that("dbProject creates project and connects", {
  tmp_dir <- withr::local_tempdir()
  proj <- dbProject$new(path = file.path(tmp_dir, "project"))
  
  expect_true(proj$is_connected())
  expect_true(DBI::dbIsValid(proj$get_conn()))
  
  proj$disconnect()
})

test_that("dbProject can disconnect and reconnect", {
  tmp_dir <- withr::local_tempdir()
  proj <- dbProject$new(path = file.path(tmp_dir, "project"))
  
  proj$disconnect()
  expect_false(proj$is_connected())
  
  proj$reconnect()
  expect_true(proj$is_connected())
  
  proj$disconnect()
})

test_that("dbProject pins connection to board", {
  tmp_dir <- withr::local_tempdir()
  proj <- dbProject$new(path = file.path(tmp_dir, "project"))
  
  board <- proj$get_board()
  expect_true("cachedConnection" %in% pins::pin_list(board))
  
  proj$disconnect()
})
