/// DTOs para ingestão GPS (POST /api/v1/locations). APP-4001.

class LocationPositionDto {
  const LocationPositionDto({
    required this.lat,
    required this.lon,
    required this.speedMps,
    required this.occurredAt,
    this.heading,
    this.accuracyMeters,
  });

  final double lat;
  final double lon;
  final double speedMps;
  final DateTime occurredAt;
  final double? heading;
  final double? accuracyMeters;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'speedMps': speedMps,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        if (heading != null) 'heading': heading,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      };
}

class LocationsBatchRequest {
  const LocationsBatchRequest({
    required this.vehicleId,
    required this.routeId,
    required this.routeVersion,
    required this.positions,
  });

  final String vehicleId;
  final String routeId;
  final int routeVersion;
  final List<LocationPositionDto> positions;

  Map<String, dynamic> toJson() => {
        'vehicleId': vehicleId,
        'routeId': routeId,
        'routeVersion': routeVersion,
        'positions': positions.map((e) => e.toJson()).toList(),
      };
}

class LocationsBatchResponse {
  const LocationsBatchResponse({
    this.accepted = 0,
    this.duplicates = 0,
    this.rejected = 0,
  });

  final int accepted;
  final int duplicates;
  final int rejected;

  factory LocationsBatchResponse.fromJson(Map<String, dynamic> json) {
    return LocationsBatchResponse(
      accepted: json['accepted'] as int? ?? 0,
      duplicates: json['duplicates'] as int? ?? 0,
      rejected: json['rejected'] as int? ?? 0,
    );
  }
}
