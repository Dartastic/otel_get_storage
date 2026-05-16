// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:get_storage/get_storage.dart';

import 'otel_get_storage_suppression.dart';

const _tracerName = 'otel_get_storage';
const _dbSystem = 'get_storage';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

Attributes _attrs({
  required String operation,
  required String container,
  String? key,
}) =>
    OTel.attributesFromMap(<String, Object>{
      Database.dbSystem.key: _dbSystem,
      Database.dbSystemName.key: _dbSystem,
      Database.dbOperation.key: operation,
      Database.dbOperationName.key: operation,
      Database.dbCollectionName.key: container,
      if (key != null) Database.dbQueryText.key: key,
    });

/// Sync variant — for `GetStorage.read` which returns immediately.
///
/// Opens a CLIENT-kind span named `get_storage <operation> <container>`
/// with `db.system=get_storage`, `db.operation`, `db.collection.name`,
/// and `db.query.text=<key>` (the storage key, treated as the
/// "query text" for the OTel DB semconv).
R tracedGetStorageCallSync<R>({
  required String operation,
  required String container,
  required R Function() invoke,
  String? key,
}) {
  if (getStorageInstrumentationSuppressed()) return invoke();
  final span = _tracer().startSpan(
    'get_storage $operation $container',
    kind: SpanKind.client,
    attributes: _attrs(operation: operation, container: container, key: key),
  );
  try {
    return invoke();
  } catch (e, st) {
    span.addAttributes(
      OTel.attributes([
        OTel.attributeString(
          ErrorResource.errorType.key,
          e.runtimeType.toString(),
        ),
      ]),
    );
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Async variant — for `write` / `remove` / `erase`.
Future<R> tracedGetStorageCall<R>({
  required String operation,
  required String container,
  required Future<R> Function() invoke,
  String? key,
}) async {
  if (getStorageInstrumentationSuppressed()) return invoke();
  final span = _tracer().startSpan(
    'get_storage $operation $container',
    kind: SpanKind.client,
    attributes: _attrs(operation: operation, container: container, key: key),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(
      OTel.attributes([
        OTel.attributeString(
          ErrorResource.errorType.key,
          e.runtimeType.toString(),
        ),
      ]),
    );
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Traced operations on [GetStorage].
///
/// `GetStorage` itself doesn't expose its container name as a public
/// field, so callers must supply it when calling the traced variants.
/// The convention is the same string you passed to
/// `GetStorage('myBox')` / `GetStorage.init('myBox')`. Defaults to
/// `GetStorage`, matching the default container.
extension OTelGetStorage on GetStorage {
  /// Traced `read`. Returns `T?`.
  T? readTraced<T>(String key, {String container = 'GetStorage'}) {
    return tracedGetStorageCallSync<T?>(
      operation: 'read',
      container: container,
      key: key,
      invoke: () => read<T>(key),
    );
  }

  /// Traced `write`.
  Future<void> writeTraced(
    String key,
    dynamic value, {
    String container = 'GetStorage',
  }) {
    return tracedGetStorageCall<void>(
      operation: 'write',
      container: container,
      key: key,
      invoke: () => write(key, value),
    );
  }

  /// Traced `remove`.
  Future<void> removeTraced(
    String key, {
    String container = 'GetStorage',
  }) {
    return tracedGetStorageCall<void>(
      operation: 'remove',
      container: container,
      key: key,
      invoke: () => remove(key),
    );
  }

  /// Traced `erase`.
  Future<void> eraseTraced({String container = 'GetStorage'}) {
    return tracedGetStorageCall<void>(
      operation: 'erase',
      container: container,
      invoke: erase,
    );
  }
}
