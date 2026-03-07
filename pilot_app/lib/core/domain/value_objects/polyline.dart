import 'package:pilot_app/core/domain/value_objects/geo_point.dart';

/// Polilinha como lista de pontos. Doc 02.
class Polyline {
  Polyline(this.points) {
    if (points.isEmpty) throw ArgumentError('points must not be empty', 'points');
  }

  final List<GeoPoint> points;
}
