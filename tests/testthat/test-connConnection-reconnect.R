# test-connConnection-reconnect.R

test_that("dbReconnect works with connConnection", {
  skip_if_not_installed("connections")
  skip_if_not_installed("duckdb")

  # Setup
  db_path <- tempfile(fileext = ".duckdb")
  on.exit(unlink(db_path), add = TRUE)

  # Create connection via connections package
  con <- connections::connection_open(duckdb::duckdb(), dbdir = db_path)

  # Close to make stale
  DBI::dbDisconnect(con@con)
  expect_false(DBI::dbIsValid(con@con))

  # Reconnect
  con <- dbReconnect(con)
  expect_true(DBI::dbIsValid(con@con))

  # Cleanup
  connections::connection_close(con)
})
