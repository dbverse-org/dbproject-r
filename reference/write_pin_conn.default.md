# Default method for write_pin_conn

Fallback method for non-database objects. Delegates directly to
pins::pin_write() for regular R objects (matrices, data.frames, vectors,
etc.)

## Usage

``` r
# Default S3 method
write_pin_conn(x, board, ...)
```

## Arguments

- x:

  Any R object

- board:

  A pins board object

- ...:

  Additional arguments passed to pins::pin_write()

## Value

Invisibly returns the input object
