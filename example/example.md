# otel_get_storage example

```dart
// example/lib/main.dart

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:otel_get_storage/otel_get_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Bring up OTel before touching storage so every traced call
  //    lands in a live tracer provider.
  await OTel.initialize(
    serviceName: 'get-storage-demo',
  );

  // 2. Init your container(s) as usual.
  await GetStorage.init('settings');
  final box = GetStorage('settings');

  // 3. Use the *Traced drop-in replacements. Each one opens a
  //    CLIENT-kind span named `get_storage <operation> <container>`
  //    with `db.system.name=get_storage`, `db.operation.name`,
  //    `db.collection.name`, and `db.query.text=<key>`.
  //
  //    GetStorage doesn't expose its container name publicly, so
  //    pass `container:` (defaults to `GetStorage`, the default
  //    container).

  // Span: `get_storage write settings`
  await box.writeTraced('theme', 'dark', container: 'settings');

  // Span: `get_storage read settings`
  final theme = box.readTraced<String>('theme', container: 'settings');
  debugPrint('theme: $theme');

  // Span: `get_storage remove settings`
  await box.removeTraced('theme', container: 'settings');

  // Span: `get_storage erase settings` (no db.query.text)
  await box.eraseTraced(container: 'settings');

  // Hot paths can opt out without touching call sites downstream:
  await runWithoutGetStorageInstrumentationAsync(() async {
    await box.writeTraced('frame.counter', 1, container: 'settings');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('otel_get_storage demo'))),
    );
  }
}
```

## Span shape

```
get_storage write settings
  db.system.name      = get_storage
  db.operation.name   = write
  db.collection.name  = settings
  db.query.text       = theme
```

On a thrown operation the span additionally records the exception,
sets `error.type` to the exception class name, and marks the span
status `Error` before rethrowing.
