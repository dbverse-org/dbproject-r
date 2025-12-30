# Convert lazy table to named view

Convert lazy table to named view

## Usage

``` r
to_view(x, name, temporary = TRUE, overwrite = TRUE, ...)
```

## Arguments

- x:

  A lazy table object (tbl_duckdb_connection)

- name:

  Character name to assign view within database

- temporary:

  Logical, if TRUE (default), the view will be deleted after the session
  ends

- overwrite:

  Logical, if TRUE (default), the view will overwrite an existing view

- ...:

  Additional arguments passed to DBI::dbExecute
