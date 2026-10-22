test_that("table names must be plain SQL names", {
  for (name in c("pbmc_3k", "Counts", "_tmp")) {
    expect_silent(.check_name(name))
  }
  for (name in list("pbmc-3k", "counts.raw", "my matrix", "3k", "x;drop", NA_character_, c("a", "b"))) {
    expect_error(.check_name(name))
  }
})

test_that("unique_table_name() leaves the random seed alone", {
  set.seed(1)
  expected <- runif(1)
  set.seed(1)
  name <- unique_table_name("tmp")
  expect_identical(runif(1), expected)
  expect_match(name, "^tmp_[[:alnum:]]+$")
  expect_false(identical(name, unique_table_name("tmp")))
})
