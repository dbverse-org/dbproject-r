# Extract and replace methods for dbData objects

Provides extraction (`[`) and replacement (`[<-`) methods for `dbData`
objects. The extractor attempts to auto-reconnect via
[`dbReconnect()`](https://dbverse-org.github.io/dbproject-r/reference/dbReconnect.md)
before returning the underlying database-backed value.

## Arguments

- x:

  A `dbData` object.

- ...:

  Additional arguments passed to the extractor.

- value:

  Replacement value for `[<-`.

## Value

For `[`: the underlying value stored in the object. For `[<-`: the
updated `dbData`.
