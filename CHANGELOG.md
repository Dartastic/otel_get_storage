# Changelog

## [0.1.0-beta.1-wip]

### Added

- `tracedGetStorageCallSync<R>(...)` / `tracedGetStorageCall<R>(...)`
  — wraps GetStorage operations in a CLIENT-kind span following the
  OTel DB semantic conventions (`db.system=get_storage`,
  `db.operation`, `db.collection.name`, `db.query.text=<key>`).
- `GetStorage.readTraced(...)`, `writeTraced(...)`, `removeTraced(...)`,
  `eraseTraced(...)` extension methods as drop-in replacements.
- Error path records `error.type`, calls `recordException`, sets the
  span status to `Error` before rethrowing.
- Zone-scoped suppression via
  `runWithoutGetStorageInstrumentation()` / `Async()`.
