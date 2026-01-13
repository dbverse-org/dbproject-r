# Validate overwrite parameter and handle existing objects

Validate overwrite parameter and handle existing objects

## Usage

``` r
.check_overwrite(conn, overwrite, name, skip_value_check = FALSE)
```

## Arguments

- conn:

  DBI connection

- overwrite:

  Logical or "PASS" token

- name:

  Table name

- skip_value_check:

  Logical, if TRUE skip value-based checks (used by dbMatrix)
