# Registry to track dbProject mappings

The registry provides O(1) lookups from database file paths to their
corresponding project paths. This enables fast reconnection when a
connection becomes invalid.

## Usage

``` r
.db_registry
```

## Format

An object of class `environment` of length 0.
