// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.
//
// We exercise the span / attribute machinery via the helper functions
// directly — no real GetStorage container is needed.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otel_get_storage/otel_get_storage.dart';

class _MemorySpanExporter implements SpanExporter {
  final List<Span> spans = [];
  bool _shutdown = false;
  @override
  Future<void> export(List<Span> s) async {
    if (_shutdown) return;
    spans.addAll(s);
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {
    _shutdown = true;
  }
}

Map<String, Object> _attrMap(Span span) => {
      for (final a in span.attributes.toList()) a.key: a.value,
    };

void main() {
  group('tracedGetStorageCall', () {
    late _MemorySpanExporter exporter;

    setUp(() async {
      await OTel.reset();
      exporter = _MemorySpanExporter();
      await OTel.initialize(
        serviceName: 'otel_get_storage-test',
        detectPlatformResources: false,
        spanProcessor: SimpleSpanProcessor(exporter),
      );
    });

    tearDown(() async {
      await OTel.shutdown();
      await OTel.reset();
    });

    test('sync read names span and sets db.* attrs', () {
      final result = tracedGetStorageCallSync<int?>(
        operation: 'read',
        container: 'GetStorage',
        key: 'user.id',
        invoke: () => 42,
      );
      expect(result, 42);
      expect(exporter.spans, hasLength(1));
      final span = exporter.spans.single;
      expect(span.name, 'get_storage read GetStorage');
      expect(span.kind, SpanKind.client);
      final attrs = _attrMap(span);
      expect(attrs['db.system.name'], 'get_storage');
      expect(attrs['db.operation.name'], 'read');
      expect(attrs['db.collection.name'], 'GetStorage');
      expect(attrs['db.query.text'], 'user.id');
    });

    test('async write names span and sets db.* attrs', () async {
      await tracedGetStorageCall<void>(
        operation: 'write',
        container: 'settings',
        key: 'theme',
        invoke: () async {},
      );
      final span = exporter.spans.single;
      expect(span.name, 'get_storage write settings');
      final attrs = _attrMap(span);
      expect(attrs['db.operation.name'], 'write');
      expect(attrs['db.collection.name'], 'settings');
      expect(attrs['db.query.text'], 'theme');
    });

    test('async erase span omits db.query.text', () async {
      await tracedGetStorageCall<void>(
        operation: 'erase',
        container: 'cache',
        invoke: () async {},
      );
      final attrs = _attrMap(exporter.spans.single);
      expect(attrs['db.operation.name'], 'erase');
      expect(attrs.containsKey('db.query.text'), isFalse);
    });

    test('records exception and sets error status on throw', () async {
      await expectLater(
        tracedGetStorageCall<void>(
          operation: 'write',
          container: 'GetStorage',
          invoke: () async => throw StateError('boom'),
        ),
        throwsA(isA<StateError>()),
      );
      final span = exporter.spans.single;
      expect(span.status, SpanStatusCode.Error);
      expect(_attrMap(span)['error.type'], 'StateError');
    });

    test('zone-scoped suppression skips span creation', () async {
      await runWithoutGetStorageInstrumentationAsync(() async {
        await tracedGetStorageCall<void>(
          operation: 'write',
          container: 'GetStorage',
          invoke: () async {},
        );
      });
      expect(exporter.spans, isEmpty);
    });
  });
}
