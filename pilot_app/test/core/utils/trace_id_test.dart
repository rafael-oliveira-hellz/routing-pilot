import 'package:flutter_test/flutter_test.dart';
import 'package:pilot_app/core/utils/trace_id.dart';

void main() {
  group('generateTraceId', () {
    test('retorna string não vazia', () {
      expect(generateTraceId(), isNotEmpty);
    });

    test('retorna formato UUID v4 (8-4-4-4-12 hex)', () {
      final id = generateTraceId();
      final pattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(pattern.hasMatch(id), isTrue, reason: 'Expected UUID v4 format: $id');
    });

    test('cada chamada gera valor diferente', () {
      final a = generateTraceId();
      final b = generateTraceId();
      expect(a, isNot(equals(b)));
    });
  });
}
