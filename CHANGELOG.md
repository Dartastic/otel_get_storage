# Changelog

## [0.2.0-wip]

### Changed

- Semantic conventions updated to the current OTel registry: deprecated
  attribute keys are no longer emitted (`db.system` -> `db.system.name`,
  `db.operation` -> `db.operation.name`, `rpc.system` -> `rpc.system.name`,
  with `rpc.service` folded into a fully-qualified `rpc.method`).
- Dependency floors raised to `dartastic_opentelemetry ^1.1.0-beta.12` and
  `dartastic_opentelemetry_api ^1.0.0-rc.1`. The previous floors declared
  compatibility with API versions that predate the semconv enums this
  package uses and could not actually resolve-and-compile.
- `repository` URL corrected to the canonical `Dartastic` org casing so
  pub.dev repository verification succeeds.

### Added

- `tracedGetStorageCallSync<R>(...)` / `tracedGetStorageCall<R>(...)`
  — wraps GetStorage operations in a CLIENT-kind span following the
  OTel DB semantic conventions (`db.system.name=get_storage`,
  `db.operation.name`, `db.collection.name`, `db.query.text=<key>`).
- `GetStorage.readTraced(...)`, `writeTraced(...)`, `removeTraced(...)`,
  `eraseTraced(...)` extension methods as drop-in replacements.
- Error path records `error.type`, calls `recordException`, sets the
  span status to `Error` before rethrowing.
- Zone-scoped suppression via
  `runWithoutGetStorageInstrumentation()` / `Async()`.
