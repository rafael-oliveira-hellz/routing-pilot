/// Ponto geográfico (lat/lon). Alinhado ao backend doc 02.
class GeoPoint {
  GeoPoint(this.latitude, this.longitude) {
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('latitude must be in [-90, 90]', 'latitude');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('longitude must be in [-180, 180]', 'longitude');
    }
  }

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPoint &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
