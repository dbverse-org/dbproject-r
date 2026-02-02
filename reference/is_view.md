# Check if a database object is a VIEW

Check if a database object is a VIEW

## Usage

``` r
is_view(conn, name)
```

## Arguments

- conn:

  DBI connection (must be duckdb)

- name:

  Character, object name to check

## Value

Logical, TRUE if the object is a VIEW
