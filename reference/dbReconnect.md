# Reconnect database connection for dbData objects

Reconnects invalid database connections for dbData objects, updating the
object with the new valid connection.

## Usage

``` r
dbReconnect(x)

# S4 method for class 'dbData'
dbReconnect(x)

# S4 method for class 'DBIConnection'
dbReconnect(x)

# S4 method for class 'connConnection'
dbReconnect(x)
```

## Arguments

- x:

  A dbData object

## Value

The dbData object with an updated connection
