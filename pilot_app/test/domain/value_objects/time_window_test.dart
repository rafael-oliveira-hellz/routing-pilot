import 'package:flutter_test/flutter_test.dart';
import 'package:pilot_app/core/domain/value_objects/time_window.dart';

void main() {
  group('TimeWindow', () {
    test('creates valid window', () {
      final start = DateTime(2025, 1, 1, 8, 0);
      final end = DateTime(2025, 1, 1, 18, 0);
      final w = TimeWindow(startAt: start, endAt: end);
      expect(w.startAt, start);
      expect(w.endAt, end);
    });

    test('accepts same start and end', () {
      final t = DateTime(2025, 1, 1, 12, 0);
      final w = TimeWindow(startAt: t, endAt: t);
      expect(w.startAt, t);
      expect(w.endAt, t);
    });

    test('throws when startAt is after endAt', () {
      final start = DateTime(2025, 1, 1, 18, 0);
      final end = DateTime(2025, 1, 1, 8, 0);
      expect(() => TimeWindow(startAt: start, endAt: end), throwsArgumentError);
    });
  });
}
