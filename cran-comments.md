## Resubmission

This is a resubmission. In this version I have:

* expanded the Description field and replaced directed/backtick quotation with
  undirected single quotation marks for 'dbverse' and 'pins';
* single-quoted the software name 'DuckDB' in the Description text;
* removed an Rd cross-reference to the not-yet-CRAN package dbMatrix;
* replaced a \dontrun{} example in dbProject.Rd with runnable code;
* added executable code chunks to connection-management.Rmd and
  troubleshooting.Rmd.

## R CMD check results

0 errors | 1 warning | 3 notes

* This is a new submission.
* The warning for `qpdf` and note for `tidy` reflect missing local system tools
  in the SCC validation environment.
* The future timestamp note reflects the local validation environment.
