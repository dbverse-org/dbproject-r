# Read a pinned dbMatrix object from a board

Read a pinned dbMatrix object from a board

## Usage

``` r
connection_pin_read(board, name, version = NULL)
```

## Arguments

- board:

  A pins board object

- name:

  The name of the pin

- version:

  The version of the pin to get (optional)

## Value

A dbMatrix object (dbSparseMatrix or dbDenseMatrix)
