import 'package:flutter_test/flutter_test.dart';
import 'package:pilot_app/core/domain/value_objects/geo_point.dart';

void main() {
  group('GeoPoint', () {
    test('creates valid point', () {
      final p = GeoPoint(0, 0);
      expect(p.latitude, 0);
      expect(p.longitude, 0);
    });

    test('accepts bounds', () {
      expect(GeoPoint(-90, -180).latitude, -90);
      expect(GeoPoint(90, 180).longitude, 180);
    });

    test('throws for latitude out of range', () {
      expect(() => GeoPoint(-91, 0), throwsArgumentError);
      expect(() => GeoPoint(90.1, 0), throwsArgumentError);
    });

    test('throws for longitude out of range', () {
      expect(() => GeoPoint(0, -181), throwsArgumentError);
      expect(() => GeoPoint(0, 181), throwsArgumentError);
    });

    test('equality', () {
      expect(GeoPoint(1, 2), equals(GeoPoint(1, 2)));
      expect(GeoPoint(1, 2).hashCode, GeoPoint(1, 2).hashCode);
      expect(GeoPoint(1, 2), isNot(equals(GeoPoint(1, 3))));
    });
  });
}
