## Resubmission

This is a resubmission. In this version I have:

* declared `dbMatrix` in Suggests because it is used by tests;
* reused canonical file-backed 'DuckDB' connections when reconnecting objects;
* rebuilt the source package with prebuilt vignettes in `inst/doc`.

## R CMD check results

0 errors | 1 warning | 1 note

Checked with `R CMD check --as-cran --no-manual`.

The warning is because `qpdf` is not installed in the local check environment.
The note is because the local check environment was unable to verify the current
time.
