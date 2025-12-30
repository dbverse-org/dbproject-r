# List remote tables, temporary tables, and views

A generic function to list tables, temporary tables, and views in a
database connection. This provides an enhanced view over
DBI::dbListTables with categorization.

## Usage

``` r
dbList(conn, ...)
```

## Arguments

- conn:

  A DBI database connection

- ...:

  Additional arguments passed to methods

## Value

Method implementations may return different formats, typically a
categorized list

## See also

[`DBI::dbListTables()`](https://dbi.r-dbi.org/reference/dbListTables.html)
