import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:pilot_app/core/utils/polyline_simplify.dart';

void main() {
  group('simplifyPolylineForDisplay', () {
    test('retorna a mesma lista quando length <= maxPoints', () {
      final points = [
        const LatLng(-23.5, -46.6),
        const LatLng(-23.6, -46.7),
      ];
      expect(simplifyPolylineForDisplay(points, maxPoints: 500), equals(points));
      expect(simplifyPolylineForDisplay(points), equals(points));
    });

    test('retorna no máximo maxPoints pontos', () {
      final points = List.generate(2000, (i) => LatLng(-23.5 + i * 0.001, -46.6));
      final result = simplifyPolylineForDisplay(points, maxPoints: 500);
      expect(result.length, equals(500));
    });

    test('mantém primeiro ponto da lista original', () {
      final points = List.generate(1000, (i) => LatLng(-23.5 + i * 0.001, -46.6));
      final result = simplifyPolylineForDisplay(points, maxPoints: 100);
      expect(result.first.latitude, equals(points.first.latitude));
      expect(result.first.longitude, equals(points.first.longitude));
    });

    test('lista vazia retorna vazia', () {
      expect(simplifyPolylineForDisplay([]), isEmpty);
    });

    test('lista com 1 ponto retorna 1 ponto', () {
      final points = [const LatLng(-23.5, -46.6)];
      expect(simplifyPolylineForDisplay(points), equals(points));
    });
  });
}
