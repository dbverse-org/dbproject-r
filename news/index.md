# Changelog

## dbProject 0.0.0.9002 (2026-01-19)

### Bug fixes

- Add default `write_pin_conn` method.

- Restore pinned objects after db directory changes via `set_dbdir`.

### Code style

- Reformat with air.

### Testing

- Ensure pins reconnect after db moves.

## dbProject 0.0.0.9001 (2026-01-13)

### Bug fixes

- Add troubleshooting vignette.

- Make pinned tbl objects round-trip reliably.

- Reconnect lazy DuckDB tbls by re-rendering SQL.

- Include arg in internal fn .check_overwrite.

- DbMatrix pin writing.

- Use bquote to force dbdir evaluation for connection serialization.

- Remove non-existent vignette from pkgdown config.

- Correct dbReconnect generic naming.

- Resolve roxygen doc warnings.

- Vignette build error.

- Add explicit package name mapping in Remotes for dbMatrix and
  dbSpatial.

### Features

- Add dbSpatial pin read/write support.

- dbProject R6 class.

- Support write/read of dbMatrix pins.

- Add `dbReconnect` method for `connConnection`.

- Add `dbLoad` generic for loading dbverse objects and export.

- Add `dbList` generic.

- DbData connection management infrastructure.

### Chore

- Tidy package metadata and imports.

- Qualify utils head in pin metadata.

- Track man/ documentation files.

- Update RoxygenNote.

- Require duckdb \>= 1.4.0.

- Remove dbMatrix and dbProject connection management files.

- Migrate to dbverse-org.

- Add Remotes for private repos and update GH Actions PAT.

### Documentation

- Document dbData extraction and conn method aliases.

- Add troubleshooting vignette.

- Add connection management vignette (WIP).

- Update getting started vignette.

- Update site map with new articles.

### Code style

- Reformat with air+jarl.

- Apply air formatting to dbproject-r.

### Refactoring

- Standardize dbProject connection API and pin handling.

- Reorg internal funcs.

- Centralize internal type check funcs.

- Rename temporary view to ‘\_tmp_view’ in row/col summary methods.

### Testing

- Add basic tests.
