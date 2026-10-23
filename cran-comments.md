## Resubmission

This is a resubmission. I added a `\usage` section to `dbData-extract.Rd`,
fixing the "Rd files without \usage" NOTE from the incoming pre-tests on
r-devel-linux-x86_64-debian-gcc (also shown for the current CRAN version on
the r-devel Debian flavors).

## Submission

This is a patch release with three bug fixes:

* table names that 'DuckDB' cannot use now give a clear error
* creating temporary table names no longer changes the user's random number
  stream after `set.seed()`
* spatial functions work on a pinned `dbSpatial` object after its project is
  reopened

## Test environments

* local R 4.6.0 on x86_64-pc-linux-gnu (Ubuntu 24.04, WSL2)

## R CMD check results

`R CMD check --as-cran --no-manual` with `NOT_CRAN` unset

* 0 errors
* 0 warnings
* 0 notes

## Reverse dependencies

I checked the 2 reverse dependencies on CRAN (dbMatrix 0.1.0 and
dbSpatial 0.1.3) with `R CMD check` against this version. Both were OK.
