# Getting Started

``` r
library(dbProject)
```

## Introduction

The `dbProject` package provides connection management for local DuckDB
databases. It uses `pins` for persistent storage and enables automatic
reconnection.

### Creating a dbProject

``` r
# Create project in temp directory
project_dir <- tempfile("dbproject_demo")
db_path <- file.path(project_dir, "demo.duckdb")

proj <- dbProject$new(path = project_dir, dbdir = db_path)
#> Creating new version '20260213T215705Z-edcb7'
#> Writing to pin 'cachedConnection'
#> Manifest file written to root folder of board, as `_pins.yaml`
proj
#> ─────────────────────────────────── dbProject ──────────────────────────────────
#> ✔ Connected
#> ── Board Content ───────────────────────────────────────────────────────────────
#> Board Path: /tmp/RtmpRJeqVg/dbproject_demo205834adee6c
#> # A tibble: 1 × 6
#>   name             type  title          created             file_size meta      
#>   <chr>            <chr> <chr>          <dttm>              <fs::byt> <list>    
#> 1 cachedConnection rds   connConnectio… 2026-02-13 21:57:05       232 <pins_met>
#> ── Database Content ────────────────────────────────────────────────────────────
#> Database Path: /tmp/RtmpRJeqVg/dbproject_demo205834adee6c/demo.duckdb
```

### Working with Data

``` r
# Get the connection and add data
con <- proj$get_conn()
mtcars_tbl <- dplyr::copy_to(con, mtcars, "mtcars", temporary = FALSE, overwrite = TRUE)
mtcars_tbl
#> # Source:   table<mtcars> [?? x 11]
#> # Database: DuckDB 1.4.4 [unknown@Linux 6.14.0-1017-azure:R 4.5.2//tmp/RtmpRJeqVg/dbproject_demo205834adee6c/demo.duckdb]
#>      mpg   cyl  disp    hp  drat    wt  qsec    vs    am  gear  carb
#>    <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#>  1  21       6  160    110  3.9   2.62  16.5     0     1     4     4
#>  2  21       6  160    110  3.9   2.88  17.0     0     1     4     4
#>  3  22.8     4  108     93  3.85  2.32  18.6     1     1     4     1
#>  4  21.4     6  258    110  3.08  3.22  19.4     1     0     3     1
#>  5  18.7     8  360    175  3.15  3.44  17.0     0     0     3     2
#>  6  18.1     6  225    105  2.76  3.46  20.2     1     0     3     1
#>  7  14.3     8  360    245  3.21  3.57  15.8     0     0     3     4
#>  8  24.4     4  147.    62  3.69  3.19  20       1     0     4     2
#>  9  22.8     4  141.    95  3.92  3.15  22.9     1     0     4     2
#> 10  19.2     6  168.   123  3.92  3.44  18.3     1     0     4     4
#> # ℹ more rows
```

### Pinning Tables

``` r
proj$pin_write(x = mtcars_tbl, name = "mtcars")
#> Creating new version '20260213T215706Z-63120'
#> Writing to pin 'mtcars'
#> Manifest file written to root folder of board, as `_pins.yaml`
proj
#> ─────────────────────────────────── dbProject ──────────────────────────────────
#> ✔ Connected
#> ── Board Content ───────────────────────────────────────────────────────────────
#> Board Path: /tmp/RtmpRJeqVg/dbproject_demo205834adee6c
#> # A tibble: 2 × 6
#>   name             type  title          created             file_size meta      
#>   <chr>            <chr> <chr>          <dttm>              <fs::byt> <list>    
#> 1 cachedConnection rds   connConnectio… 2026-02-13 21:57:05       232 <pins_met>
#> 2 mtcars           rds   mtcars: a pin… 2026-02-13 21:57:06       268 <pins_met>
#> ── Database Content ────────────────────────────────────────────────────────────
#> Database Path: /tmp/RtmpRJeqVg/dbproject_demo205834adee6c/demo.duckdb
#> ℹ Tables:
#> • mtcars
```

### Disconnecting and Reconnecting

``` r
# Disconnect
proj$disconnect()
proj
#> ─────────────────────────────────── dbProject ──────────────────────────────────
#> ✖ Disconnected
#> ── Board Content ───────────────────────────────────────────────────────────────
#> Board Path: /tmp/RtmpRJeqVg/dbproject_demo205834adee6c
#> # A tibble: 2 × 6
#>   name             type  title          created             file_size meta      
#>   <chr>            <chr> <chr>          <dttm>              <fs::byt> <list>    
#> 1 cachedConnection rds   connConnectio… 2026-02-13 21:57:05       232 <pins_met>
#> 2 mtcars           rds   mtcars: a pin… 2026-02-13 21:57:06       268 <pins_met>
#> ── Database Content ────────────────────────────────────────────────────────────
#> ℹ No active connection.

# Reconnect
proj$reconnect()
#> 
#> Attaching package: 'connections'
#> The following objects are masked from 'package:dbProject':
#> 
#>     connection_pin_read, read_pin_conn, write_pin_conn
#> Loading required package: DBI
proj
#> ─────────────────────────────────── dbProject ──────────────────────────────────
#> ✔ Connected
#> ── Board Content ───────────────────────────────────────────────────────────────
#> Board Path: /tmp/RtmpRJeqVg/dbproject_demo205834adee6c
#> # A tibble: 2 × 6
#>   name             type  title          created             file_size meta      
#>   <chr>            <chr> <chr>          <dttm>              <fs::byt> <list>    
#> 1 cachedConnection rds   connConnectio… 2026-02-13 21:57:05       232 <pins_met>
#> 2 mtcars           rds   mtcars: a pin… 2026-02-13 21:57:06       268 <pins_met>
#> ── Database Content ────────────────────────────────────────────────────────────
#> Database Path: /tmp/RtmpRJeqVg/dbproject_demo205834adee6c/demo.duckdb
#> ℹ Tables:
#> • mtcars
```

### Reading Pinned Tables

``` r
restored <- proj$pin_read("mtcars")
head(restored, 5)
#> # Source:   SQL [?? x 11]
#> # Database: DuckDB 1.4.4 [unknown@Linux 6.14.0-1017-azure:R 4.5.2//tmp/RtmpRJeqVg/dbproject_demo205834adee6c/demo.duckdb]
#>     mpg   cyl  disp    hp  drat    wt  qsec    vs    am  gear  carb
#>   <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1  21       6   160   110  3.9   2.62  16.5     0     1     4     4
#> 2  21       6   160   110  3.9   2.88  17.0     0     1     4     4
#> 3  22.8     4   108    93  3.85  2.32  18.6     1     1     4     1
#> 4  21.4     6   258   110  3.08  3.22  19.4     1     0     3     1
#> 5  18.7     8   360   175  3.15  3.44  17.0     0     0     3     2
```

### Cleanup

``` r
proj$disconnect()
unlink(project_dir, recursive = TRUE)
```
