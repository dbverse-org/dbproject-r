test_that("table names must be plain SQL names", {
  for (name in c("pbmc_3k", "Counts", "_tmp")) {
    expect_silent(.check_name(name))
  }
  for (name in list("pbmc-3k", "counts.raw", "my matrix", "3k", "x;drop", NA_character_, c("a", "b"))) {
    expect_error(.check_name(name))
  }
})
