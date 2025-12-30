# Convert lazy table to named VIEW

Convert lazy table to named VIEW

## Usage

``` r
# S4 method for class 'ANY'
to_view(x, name, temporary = TRUE, overwrite = TRUE, ...)
```

## Arguments

- x:

  `tbl_sql` **Required**. `tbl_sql` object to convert to a VIEW.

- name:

  `character` **Required**. Name to assign VIEW within database.
  Auto-generated if none provided with prefix `"tmp_view_"`

- temporary:

  `logical` If `TRUE` (default), the VIEW will not be saved in the
  database

- overwrite:

  `logical` If `TRUE` (default), the VIEW will overwrite an existing
  VIEW of the same name

- ...:

  Additional arguments passed to
  [`DBI::dbExecute()`](https://dbi.r-dbi.org/reference/dbExecute.html)
