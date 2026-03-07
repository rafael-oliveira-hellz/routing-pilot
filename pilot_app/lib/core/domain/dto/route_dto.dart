import 'package:pilot_app/core/domain/value_objects/geo_point.dart';

// DTOs de request/response para APIs de rota. Doc 03, Sprint 2.

class RoutePointDto {
  const RoutePointDto({
    required this.latitude,
    required this.longitude,
    this.identifier,
    this.loadingDurationMs,
    this.unloadingDurationMs,
  });

  final double latitude;
  final double longitude;
  final String? identifier;
  final int? loadingDurationMs;
  final int? unloadingDurationMs;

  factory RoutePointDto.fromGeoPoint(GeoPoint p, {String? id}) {
    return RoutePointDto(
      latitude: p.latitude,
      longitude: p.longitude,
      identifier: id,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (identifier != null) 'identifier': identifier,
        if (loadingDurationMs != null) 'loadingDurationMs': loadingDurationMs,
        if (unloadingDurationMs != null) 'unloadingDurationMs': unloadingDurationMs,
      };
}

class RouteStopDto {
  const RouteStopDto({
    required this.latitude,
    required this.longitude,
    required this.sequenceOrder,
    this.identifier,
  });

  final double latitude;
  final double longitude;
  final int sequenceOrder;
  final String? identifier;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'sequenceOrder': sequenceOrder,
        if (identifier != null) 'identifier': identifier,
      };
}

class RouteConstraintDto {
  const RouteConstraintDto({
    this.maxVehicleCount,
    this.maxDurationSeconds,
    this.maxDistanceMeters,
    this.avoidTolls = false,
    this.avoidTunnels = false,
  });

  final int? maxVehicleCount;
  final int? maxDurationSeconds;
  final int? maxDistanceMeters;
  final bool avoidTolls;
  final bool avoidTunnels;

  Map<String, dynamic> toJson() => {
        if (maxVehicleCount != null) 'maxVehicleCount': maxVehicleCount,
        if (maxDurationSeconds != null) 'maxDurationSeconds': maxDurationSeconds,
        if (maxDistanceMeters != null) 'maxDistanceMeters': maxDistanceMeters,
        'avoidTolls': avoidTolls,
        'avoidTunnels': avoidTunnels,
      };
}

class RouteRequestDto {
  const RouteRequestDto({
    required this.points,
    this.stops = const [],
    this.constraints,
    this.departureAt,
  });

  final List<RoutePointDto> points;
  final List<RouteStopDto> stops;
  final RouteConstraintDto? constraints;
  final DateTime? departureAt;

  Map<String, dynamic> toJson() => {
        'points': points.map((e) => e.toJson()).toList(),
        'stops': stops.map((e) => e.toJson()).toList(),
        if (constraints != null) 'constraints': constraints!.toJson(),
        if (departureAt != null) 'departureAt': departureAt!.toIso8601String(),
      };
}

class RouteRequestResponse {
  const RouteRequestResponse({
    required this.id,
    this.status,
  });

  final String id;
  final String? status;

  factory RouteRequestResponse.fromJson(Map<String, dynamic> json) {
    return RouteRequestResponse(
      id: json['id'] as String,
      status: json['status'] as String?,
    );
  }
}
