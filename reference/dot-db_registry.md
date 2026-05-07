# Registry to track live connections

The registry provides O(1) lookups from database file paths to cached
live connections. This enables fast reconnection and connection
de-duplication when a connection becomes invalid.

Entries are keyed by normalized database file path. Live connections are
stored under `paste0("conn:", dir)`.

## Usage

``` r
.db_registry
```

## Format

An object of class `environment` of length 0.
