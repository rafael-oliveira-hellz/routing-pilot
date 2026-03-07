import 'package:latlong2/latlong.dart';

/// Simplifica polyline para evitar travar UI com muitos pontos. APP-3001.
/// Retorna no máximo [maxPoints] pontos (amostragem uniforme).
List<LatLng> simplifyPolylineForDisplay(List<LatLng> points, {int maxPoints = 500}) {
  if (points.length <= maxPoints) return points;
  final step = points.length / maxPoints;
  return List.generate(maxPoints, (i) {
    final index = (i * step).floor().clamp(0, points.length - 1);
    return points[index];
  });
}
