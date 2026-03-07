import 'dart:math' as math;

import 'package:pilot_app/core/domain/value_objects/geo_point.dart';

/// Tile de mapa (slippy map) para agrupamento espacial. Alinhado ao backend doc 02.
class RegionTile {
  const RegionTile(this.zoomLevel, this.tileX, this.tileY)
      : assert(zoomLevel >= 0);

  final int zoomLevel;
  final int tileX;
  final int tileY;

  /// Converte [GeoPoint] em tile no nível [zoom] (ex.: zoom 14).
  static RegionTile fromGeoPoint(GeoPoint p, int zoom) {
    final n = 1 << zoom;
    final x = ((p.longitude + 180.0) / 360.0 * n).floor();
    final latRad = p.latitude * (math.pi / 180.0);
    final y = ((1.0 -
                math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) /
                    math.pi) /
            2.0 *
            n)
        .floor();
    return RegionTile(zoom, x.clamp(0, n - 1), y.clamp(0, n - 1));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegionTile &&
          zoomLevel == other.zoomLevel &&
          tileX == other.tileX &&
          tileY == other.tileY;

  @override
  int get hashCode => Object.hash(zoomLevel, tileX, tileY);
}
