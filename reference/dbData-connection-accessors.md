# Connection accessor methods for dbData objects

These methods provide a unified interface for accessing and setting
database connections across all dbverse packages. They handle different
connection storage patterns across various subclasses.

Get or set the database connection for a `dbData` object.

## Usage

``` r
conn(x)

conn(x) <- value

# S4 method for class 'dbData'
conn(x)

# S4 method for class 'dbData'
conn(x) <- value
```

## Arguments

- x:

  A `dbData` object

- value:

  A `DBIConnection` object

## Value

For getter: The database connection. For setter: The updated object

For getter: `DBIConnection`. For setter: Updated object.

## Details

The connection accessor methods support multiple implementation
patterns:

1.  Nested connection: Some classes (like dbMatrix) store connections in
    `value$src$con`

2.  dbplyr connections: Objects with tbl_duckdb_connection values can
    use dbplyr::remote_con()

The implementation automatically tries these access patterns in order of
specificity, falling back to more generic approaches if needed.

Auto-reconnects if the current connection is invalid.

## See also

[dbData](https://dbverse-org.github.io/dbproject-r/reference/dbData-class.md)
