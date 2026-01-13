# Read a pinned dbMatrix from pins board

S3 method for reading dbMatrix objects from a pins board. Reconstructs
the full dbMatrix object.

## Usage

``` r
# S3 method for class 'conn_matrix_table'
read_pin_conn(x)
```

## Arguments

- x:

  A pinned conn_matrix_table object

## Value

A dbMatrix object (dbSparseMatrix or dbDenseMatrix)
