# List remote tables, temporary tables, and views

Pretty prints tables, temporary tables, and views in the database.

## Usage

``` r
# S4 method for class 'DBIConnection'
dbList(conn)
```

## Arguments

- conn:

  A DBIConnection object, as returned by
  [`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html).

## Details

Similar to DBI::dbListTables, but categorizes tables into three
categories:

- Tables

- Temporary Tables (these will be removed when the connection is closed)

- Views (these may be removed when the connection is closed)
