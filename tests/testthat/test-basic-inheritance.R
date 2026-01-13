test_that("dbData class exists and is virtual", {
  expect_true(isClass("dbData"))
  expect_true(getClass("dbData")@virtual)
})

test_that("dbData can be subclassed", {
  setClass("TestDbData", contains = "dbData")
  obj <- new("TestDbData")

  expect_true(is(obj, "dbData"))
  expect_true("value" %in% slotNames(obj))
  expect_true("name" %in% slotNames(obj))
})
