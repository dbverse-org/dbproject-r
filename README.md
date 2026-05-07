
# dbProject

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/dbProject)](https://CRAN.R-project.org/package=dbProject)

<!-- badges: end -->

The goal of dbProject is to manage dbData objects and database connections in the dbverse ecosystem.

## Installation

You can install the development version of dbProject like so:

``` r
pak::pak("dbverse-org/dbproject-r")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(dbProject)

project_dir <- tempfile("dbproject_demo")
project <- dbProject$new(path = project_dir)
con <- project$get_conn()

DBI::dbWriteTable(con, "mtcars", mtcars)
DBI::dbReadTable(con, "mtcars")

project$disconnect()
unlink(project_dir, recursive = TRUE)
```
