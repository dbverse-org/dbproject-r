# dbProject: database connection and table management

R6 class for managing DuckDB connections and pinning lazy database
tables. Wraps a
[`pins::board_folder()`](https://pins.rstudio.com/reference/board_folder.html)
with a cached connection object stored as "cachedConnection" for
automatic reconnection.

## See also

[`conn()`](https://dbverse-org.github.io/dbproject-r/reference/dbData-connection-accessors.md)
S4 generic for dbData objects

## Methods

### Public methods

- [`dbProject$new()`](#method-dbProject-new)

- [`dbProject$disconnect()`](#method-dbProject-disconnect)

- [`dbProject$reconnect()`](#method-dbProject-reconnect)

- [`dbProject$set_dbdir()`](#method-dbProject-set_dbdir)

- [`dbProject$get_conn()`](#method-dbProject-get_conn)

- [`dbProject$get_board()`](#method-dbProject-get_board)

- [`dbProject$pin_write()`](#method-dbProject-pin_write)

- [`dbProject$pin_delete()`](#method-dbProject-pin_delete)

- [`dbProject$pin_read()`](#method-dbProject-pin_read)

- [`dbProject$restore()`](#method-dbProject-restore)

- [`dbProject$dbRemoveTable()`](#method-dbProject-dbRemoveTable)

- [`dbProject$dbRemoveView()`](#method-dbProject-dbRemoveView)

- [`dbProject$print()`](#method-dbProject-print)

- [`dbProject$is_connected()`](#method-dbProject-is_connected)

- [`dbProject$clone()`](#method-dbProject-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new dbProject object.

#### Usage

    dbProject$new(path, ...)

#### Arguments

- `path`:

  A character string specifying the folder path for pins.

- `...`:

  Additional arguments passed to
  [`connections::connection_open()`](https://rstudio.github.io/connections/reference/connection_open.html)

------------------------------------------------------------------------

### Method `disconnect()`

Close the current connection, if any.

#### Usage

    dbProject$disconnect()

------------------------------------------------------------------------

### Method `reconnect()`

Reconnect to the database in the project.

#### Usage

    dbProject$reconnect()

------------------------------------------------------------------------

### Method `set_dbdir()`

Update the project's cached DuckDB database path.

#### Usage

    dbProject$set_dbdir(dbdir)

#### Arguments

- `dbdir`:

  Path to the DuckDB database file.

#### Details

Overwrites the "cachedConnection" pin with a connection that uses the
provided `dbdir`. Uses forced evaluation to avoid pins restoring a
connection that references an out-of-scope variable.

------------------------------------------------------------------------

### Method `get_conn()`

Retrieve the DBI connection from the project, reconnecting if necessary.

#### Usage

    dbProject$get_conn()

#### Returns

A `DBIConnection` object for direct database operations.

------------------------------------------------------------------------

### Method `get_board()`

Return the
[`pins::board_folder()`](https://pins.rstudio.com/reference/board_folder.html)
object used by the project.

#### Usage

    dbProject$get_board()

#### Returns

The
[`pins::board_folder()`](https://pins.rstudio.com/reference/board_folder.html)
object.

------------------------------------------------------------------------

### Method `pin_write()`

Write a lazy database tbl to the project.

#### Usage

    dbProject$pin_write(x, name)

#### Arguments

- `x`:

  A [`dplyr::tbl`](https://dplyr.tidyverse.org/reference/tbl.html)
  object to be written to the board.

- `name`:

  A character string specifying the name of the pin.

#### Returns

The materialized object (for dbMatrix/dbSpatial) pointing to permanent
table, or invisibly returns the dbProject object for other types.

------------------------------------------------------------------------

### Method `pin_delete()`

Delete a pin from the project.

#### Usage

    dbProject$pin_delete(name, ...)

#### Arguments

- `name`:

  A character string specifying the name of the pin to delete.

- `...`:

  Additional arguments passed to
  [`pins::pin_delete()`](https://pins.rstudio.com/reference/pin_delete.html).

#### Returns

Invisibly returns the dbProject object for method chaining.

------------------------------------------------------------------------

### Method `pin_read()`

Read a pinned object from the project's board.

#### Usage

    dbProject$pin_read(name)

#### Arguments

- `name`:

  A character string specifying the name of the pin.

#### Returns

The object stored in the specified pin.

------------------------------------------------------------------------

### Method `restore()`

Restore all pins from the board manifest.

#### Usage

    dbProject$restore()

#### Details

Reads the board manifest and restores the cached connection and all
pinned objects. The connection is restored internally, while other
pinned objects are returned as a named list for the user to assign.

#### Returns

A named list of restored pinned objects (excluding the connection).

#### Examples

    \dontrun{
    # Restore and assign objects
    objs <- proj$restore()
    my_matrix <- objs$my_matrix
    my_spatial <- objs$my_spatial
    }

------------------------------------------------------------------------

### Method `dbRemoveTable()`

Remove a table from the connected database

#### Usage

    dbProject$dbRemoveTable(name)

#### Arguments

- `name`:

  A character string specifying the name of the table to remove

#### Returns

Invisibly returns the dbProject object for method chaining

------------------------------------------------------------------------

### Method `dbRemoveView()`

Remove a view from the connected database

#### Usage

    dbProject$dbRemoveView(name)

#### Arguments

- `name`:

  A character string specifying the name of the table to remove

#### Returns

Invisibly returns the dbProject object for method chaining

------------------------------------------------------------------------

### Method [`print()`](https://rdrr.io/r/base/print.html)

Print summary information, including connection status, path, and board
details.

#### Usage

    dbProject$print(...)

#### Arguments

- `...`:

  Unused arguments (for consistency with generic print method)

------------------------------------------------------------------------

### Method `is_connected()`

Check if there is an active database connection.

#### Usage

    dbProject$is_connected()

#### Returns

A logical value indicating whether the project has an active connection.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    dbProject$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
## ------------------------------------------------
## Method `dbProject$restore`
## ------------------------------------------------

if (FALSE) { # \dontrun{
# Restore and assign objects
objs <- proj$restore()
my_matrix <- objs$my_matrix
my_spatial <- objs$my_spatial
} # }
```
