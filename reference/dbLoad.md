# Load a dbverse object from the database

Generic function to reconstruct dbverse objects (dbMatrix, dbSpatial,
etc.) from tables stored in a database connection.

## Usage

``` r
dbLoad(conn, name, class, ...)
```

## Arguments

- conn:

  A DBI database connection

- name:

  Character name of the table/view in the database

- class:

  Character class name of the object to load (e.g., "dbMatrix",
  "dbSpatial")

- ...:

  Additional arguments passed to specific methods

## Value

A dbverse object of the specified class
