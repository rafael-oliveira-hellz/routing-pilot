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

// --- APP-3002: resultado da rota otimizada e recálculo ---

class RouteWaypointDto {
  const RouteWaypointDto({
    required this.latitude,
    required this.longitude,
    this.sequenceOrder,
    this.identifier,
  });

  final double latitude;
  final double longitude;
  final int? sequenceOrder;
  final String? identifier;

  factory RouteWaypointDto.fromJson(Map<String, dynamic> json) {
    return RouteWaypointDto(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      sequenceOrder: json['sequenceOrder'] as int?,
      identifier: json['identifier'] as String?,
    );
  }
}

class RouteSegmentDto {
  const RouteSegmentDto({
    this.distanceMeters,
    this.durationSeconds,
    this.fromWaypointIndex,
    this.toWaypointIndex,
    this.trafficLevel,
  });

  final int? distanceMeters;
  final int? durationSeconds;
  final int? fromWaypointIndex;
  final int? toWaypointIndex;
  /// HEAVY = trânsito intenso (trecho em vermelho no mapa), null/NORMAL = azul.
  final String? trafficLevel;

  bool get isHeavyTraffic =>
      trafficLevel != null && trafficLevel!.toUpperCase() == 'HEAVY';

  factory RouteSegmentDto.fromJson(Map<String, dynamic> json) {
    return RouteSegmentDto(
      distanceMeters: json['distanceMeters'] as int?,
      durationSeconds: json['durationSeconds'] as int?,
      fromWaypointIndex: json['fromWaypointIndex'] as int?,
      toWaypointIndex: json['toWaypointIndex'] as int?,
      trafficLevel: json['trafficLevel'] as String?,
    );
  }
}

/// Geometria do caminho: lista de pontos [lat, lon] ou objetos com latitude/longitude.
List<GeoPoint> pathGeometryFromJson(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    final out = <GeoPoint>[];
    for (final e in value) {
      if (e is List && e.length >= 2) {
        out.add(GeoPoint(
          (e[0] as num).toDouble(),
          (e[1] as num).toDouble(),
        ));
      } else if (e is Map<String, dynamic>) {
        final lat = e['latitude'] ?? e['lat'];
        final lon = e['longitude'] ?? e['lon'] ?? e['lng'];
        if (lat != null && lon != null) {
          out.add(GeoPoint((lat as num).toDouble(), (lon as num).toDouble()));
        }
      }
    }
    return out;
  }
  return [];
}

class RouteResultDto {
  const RouteResultDto({
    required this.id,
    required this.routeRequestId,
    required this.status,
    this.totalDistanceMeters,
    this.totalDurationSeconds,
    this.waypointCount,
    this.pathGeometry = const [],
    this.segments = const [],
    this.waypoints = const [],
    this.recalculationReason,
  });

  final String id;
  final String routeRequestId;
  final String status;
  final int? totalDistanceMeters;
  final int? totalDurationSeconds;
  final int? waypointCount;
  final List<GeoPoint> pathGeometry;
  final List<RouteSegmentDto> segments;
  final List<RouteWaypointDto> waypoints;
  final String? recalculationReason;

  factory RouteResultDto.fromJson(Map<String, dynamic> json) {
    final pathRaw = json['pathGeometry'];
    return RouteResultDto(
      id: json['id'] as String,
      routeRequestId: json['routeRequestId'] as String,
      status: (json['status'] as String?) ?? 'UNKNOWN',
      totalDistanceMeters: json['totalDistanceMeters'] as int?,
      totalDurationSeconds: json['totalDurationSeconds'] as int?,
      waypointCount: json['waypointCount'] as int?,
      pathGeometry: pathGeometryFromJson(pathRaw),
      segments: (json['segments'] as List<dynamic>?)
              ?.map((e) => RouteSegmentDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      waypoints: (json['waypoints'] as List<dynamic>?)
              ?.map((e) => RouteWaypointDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      recalculationReason: json['recalculationReason'] as String?,
    );
  }
}

class OptimizationRunDto {
  const OptimizationRunDto({
    required this.id,
    this.status,
    this.startedAt,
    this.completedAt,
    this.reason,
  });

  final String id;
  final String? status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? reason;

  factory OptimizationRunDto.fromJson(Map<String, dynamic> json) {
    return OptimizationRunDto(
      id: json['id'] as String,
      status: json['status'] as String?,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      reason: json['reason'] as String?,
    );
  }
}
