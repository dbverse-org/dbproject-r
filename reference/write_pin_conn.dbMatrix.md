# Write a dbMatrix object to a pins board

S3 method for writing dbMatrix objects to a pins board while maintaining
connection state and metadata consistent with the connections package.
Handles ops slot persistence for lazy affine transformations.

## Usage

``` r
# S3 method for class 'dbMatrix'
write_pin_conn(x, board, name, ...)
```

## Arguments

- x:

  A
  [`dbMatrix::dbMatrix`](https://dbverse-org.github.io/dbmatrix-r/reference/dbMatrix-class.html)
  object (dbSparseMatrix or dbDenseMatrix)

- board:

  A pins
  [`pins::board_folder`](https://pins.rstudio.com/reference/board_folder.html)
  object

- name:

  Name for the pin (required)

- ...:

  Additional arguments passed to
  [`pins::pin_write()`](https://pins.rstudio.com/reference/pin_read.html)

## Value

Invisibly returns the input object
