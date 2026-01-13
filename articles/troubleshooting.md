# Troubleshooting & FAQ

This vignette covers common issues you may encounter when using dbverse
packages and how to resolve them.

## Database Lock Errors

### Error: “Could not set lock on file”

    Error: Could not set lock on file "path/to/database.duckdb": 
    Conflicting lock is held in /path/to/R (PID 12345) by user...

**Cause**: DuckDB uses file-level locking to ensure data integrity. Only
one process can write to a database file at a time. This error occurs
when:

- Another R session is connected to the same database
- A previous R session didn’t disconnect properly before closing
- Multiple scripts are trying to access the same database simultaneously

**Solutions**:

1.  **Kill the conflicting process** (shown in the error message):

    ``` bash
    # Replace 12345 with the actual PID from the error
    kill 12345
    ```

2.  **Restart RStudio** to close all R processes

3.  **Properly disconnect before closing sessions**:

    ``` r
    # Always disconnect when done
    proj$disconnect()

    # Or for direct DBI connections:
    DBI::dbDisconnect(con, shutdown = TRUE)
    ```

4.  **Use read-only mode for concurrent access**:

    ``` r
    # Multiple processes can read simultaneously
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "path/to/db", read_only = TRUE)
    ```

------------------------------------------------------------------------

## Connection Issues

### Error: “No active or cached connection available”

**Cause**: The `dbProject` connection has been closed or was never
established. **Solution**: Reconnect to the database:

``` r
proj$reconnect()
```

### Objects showing “Error: Column references …” after restart

**Cause**: Lazy table references become stale after R restarts because
the connection is lost.

**Solution**: Use `dbProject` for automatic reconnection:

``` r
# Create project (saves connection info)
proj <- dbProject$new(path = "my_project", dbdir = "data.duckdb")

# After restart, just reload
proj <- dbProject$new(path = "my_project", dbdir = "data.duckdb")
proj$reconnect()

# Pinned objects are automatically reconnected
my_data <- proj$pin_read("my_table")
```

------------------------------------------------------------------------

## Memory Issues

### Large datasets causing R to crash

**Cause**: Accidentally collecting large lazy tables into memory.

**Prevention**:

1.  **Avoid `collect()` on large tables**:

    ``` r
    # BAD - loads entire table into memory
    big_df <- big_table |> collect()

    # GOOD - keep lazy, push computation to database and only collect what's needed
    result <- big_table |> 
      filter(gene == "BRCA1") |>
      collect()
    ```

2.  **Use `pin_write()` to materialize intermediates to disk**:

    ``` r
    # Materialize to database, not memory
    filtered_data <- proj$pin_write(x = lazy_filtered, name = "filtered")
    ```

------------------------------------------------------------------------

## Package-Specific Issues

### dbMatrix: Slow operations after many transformations

**Cause**: Complex lazy query chains can cause performance issues.

**Solution**: Use
[`dplyr::compute()`](https://dplyr.tidyverse.org/reference/compute.html)
or `pin_write()` to materialize intermediate results:

``` r
# Materialize after expensive operations
complex_result <- my_dbMatrix |>
  some_expensive_transform() |> # e.g. a function containing several SQL joins
  dplyr::compute(name = "materialized", temporary = FALSE)
```

------------------------------------------------------------------------

## Getting Help

If you encounter issues not covered here:

1.  Checkout the specific [dbverse package on our GitHub
    organization](https://github.com/dbverse-org).
2.  Ensure you’re using the latest dbverse package versions.
3.  Include a minimal reproducible example when reporting issues.
