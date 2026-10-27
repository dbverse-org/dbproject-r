# Extract and replace methods for dbData objects

Provides extraction (`[`) and replacement (`[<-`) methods for `dbData`
objects. The extractor attempts to auto-reconnect via
[`dbReconnect()`](https://dbverse-org.github.io/dbproject-r/reference/dbReconnect.md)
before returning the underlying database-backed value.

## Usage

``` r
# S4 method for class 'dbData'
x[i, j, ..., drop = TRUE]

# S4 method for class 'dbData'
x[i, j, ...] <- value
```

## Arguments

- x:

  A `dbData` object.

- i, j, drop:

  Ignored; `x[]` returns or replaces the whole value.

- ...:

  Additional arguments passed to the extractor.

- value:

  Replacement value for `[<-`.

## Value

For `[`: the underlying value stored in the object. For `[<-`: the
updated `dbData`.
