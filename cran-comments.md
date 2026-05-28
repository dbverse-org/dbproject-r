## Resubmission

This is a resubmission. In this version I have:

* declared `dbMatrix` in Suggests because it is used by tests;
* reused canonical file-backed 'DuckDB' connections when reconnecting objects.

## R CMD check results

0 errors | 0 warnings | 2 notes

Checked with `R CMD check --as-cran --no-manual --ignore-vignettes`.

The notes are for the missing prebuilt vignette index and local Pandoc not being
installed for checking `README.md` and `NEWS.md`.
