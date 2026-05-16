# otel_get_storage

OpenTelemetry instrumentation for
[`package:get_storage`](https://pub.dev/packages/get_storage).

Wraps GetStorage operations in `CLIENT`-kind spans following the OTel
DB semantic conventions — `db.system=get_storage`, `db.operation`,
`db.collection.name`, `db.query.text=<key>`, plus error attributes
when an operation throws.

## Install

```yaml
dependencies:
  get_storage: ^2.1.1
  otel_get_storage: ^0.1.0
```

## Use

```dart
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:get_storage/get_storage.dart';
import 'package:otel_get_storage/otel_get_storage.dart';

Future<void> main() async {
  await OTel.initialize(
    serviceName: 'my-app',
    endpoint: 'http://localhost:4317',
  );

  await GetStorage.init('settings');
  final box = GetStorage('settings');

  // Drop-in replacements for the standard methods:
  await box.writeTraced('theme', 'dark', container: 'settings');
  final theme = box.readTraced<String>('theme', container: 'settings');
  await box.removeTraced('theme', container: 'settings');
  await box.eraseTraced(container: 'settings');
}
```

`GetStorage` doesn't expose its container name as a public field —
pass `container:` so the span gets `db.collection.name` right.
Defaults to `GetStorage`, matching the default container.

## Span shape

| OTel attribute       | Source                              |
|----------------------|-------------------------------------|
| `db.system`          | hardcoded `get_storage`             |
| `db.operation`       | `read` / `write` / `remove` / `erase` |
| `db.collection.name` | the container name                  |
| `db.query.text`      | the storage key (omitted for erase) |
| `error.type`         | exception class (on throw)          |

## Suppression

```dart
await runWithoutGetStorageInstrumentationAsync(() async {
  await box.writeTraced('hot-loop-key', value);  // skipped
});
```

## License

Apache 2.0 — copyright Mindful Software LLC.
