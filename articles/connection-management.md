# Connection Management

## The Problem

Database connections in R are stateful and can be easy to lose track of:

``` r

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "data.duckdb")
tbl1 <- dplyr::tbl(con, "table1")
# ... 50 lines later: Is the connection still valid? Who closed it?
```

## dbProject’s Solution

An R6 class that centralizes your connection and pinned tables:

``` r

library(dbProject)

project_path <- tempfile("dbproject-")
proj <- dbProject$new(path = project_path)
#> Creating new version '20260507T171733Z-72241'
#> Writing to pin 'cachedConnection'
#> Manifest file written to root folder of board, as `_pins.yaml`
expression_data <- data.frame(gene = c("A", "B"), count = c(10, 20))
proj$pin_write(expression_data, "expression_data")
#> Guessing `type = 'rds'`
#> Creating new version '20260507T171733Z-f8e46'
#> Writing to pin 'expression_data'
#> Manifest file written to root folder of board, as `_pins.yaml`

# Later (even after R restart):
proj$reconnect()
#> 
#> Attaching package: 'connections'
#> 
#> The following objects are masked from 'package:dbProject':
#> 
#>     connection_pin_read, read_pin_conn, write_pin_conn
#> 
#> Loading required package: DBI
my_tbl <- proj$pin_read("expression_data")
my_tbl
#>   gene count
#> 1    A    10
#> 2    B    20
```

## DBI Compatibility

dbProject works alongside DBI, not instead of it:

| Approach     | When to Use                                |
|--------------|--------------------------------------------|
| DBI directly | Quick scripts, one-off analysis            |
| dbProject    | Multi-session work, centralized management |

Both approaches get automatic reconnection via the `dbData` base class.

## Convenience Features

dbProject includes small convenience functions to help manage and
organize database connections in R.

[`DBI::dbListTables()`](https://dbi.r-dbi.org/reference/dbListTables.html)
is useful when you just need the table names in a connection:

``` r

con <- proj$get_conn()
DBI::dbWriteTable(
  con,
  "sample_metadata",
  data.frame(sample = c("sample1", "sample2"), n = c(100, 120)),
  overwrite = TRUE
)
DBI::dbExecute(
  con,
  "CREATE OR REPLACE TEMPORARY TABLE current_batch AS
   SELECT * FROM sample_metadata"
)
#> [1] 2
DBI::dbExecute(
  con,
  "CREATE OR REPLACE VIEW sample_summary AS
   SELECT sample, n FROM sample_metadata"
)
#> [1] 0

DBI::dbListTables(con)
#> [1] "current_batch"   "sample_metadata" "sample_summary"
```

[`dbList()`](https://dbverse-org.github.io/dbproject-r/reference/dbList.md)
keeps the same DBI connection but groups the results by table type,
which makes it easier to distinguish persistent tables from temporary
tables and views:

``` r

dbList(con)
#> Tables: 
#> [1] "sample_metadata"
#> Temporary Tables: 
#> [1] "current_batch"
#> Views: 
#> [1] "sample_summary"
```

## Core Concepts

### Mutable State (R6)

``` r

proj <- dbProject$new(path = "my_analysis/")

# These modify the same object - no reassignment needed
proj$disconnect()
proj$reconnect()
proj$pin_write(my_tbl, "results")
```

### Centralized Management

``` r

proj
#> ── dbProject ──────────────────────────────────────────
#> ✓ Connected
#> ── Board Content ──────────────────────────────────────
#>   name              type
#>   expression_data   tbl
#> ── Database Content ───────────────────────────────────
#> ℹ Tables: expression_raw, cell_types
```

### Automatic Reconnection

The empty extract `[]` method on all dbverse objects auto-reconnects if
the connection is stale:

``` r

mat[]  # Can be either a DBI connection or a dbProject connection
```

## Working with Pins

``` r

proj$pin_write(my_tbl, "results")   # Save lazy table
my_tbl <- proj$pin_read("results") # Restore reference
proj$pin_delete("old_results")     # Clean up
```
