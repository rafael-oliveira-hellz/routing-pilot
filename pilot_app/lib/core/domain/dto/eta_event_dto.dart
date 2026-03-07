/// Eventos de rota/ETA via WebSocket. Doc 11. APP-4002, APP-5001.

class EtaUpdatedEventDto {
  const EtaUpdatedEventDto({
    required this.remainingSeconds,
    required this.confidence,
    required this.degraded,
    required this.distanceRemainingMeters,
  });

  final int remainingSeconds;
  final double confidence;
  final bool degraded;
  final double distanceRemainingMeters;

  factory EtaUpdatedEventDto.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? json;
    return EtaUpdatedEventDto(
      remainingSeconds: (payload['remainingSeconds'] as int?) ?? 0,
      confidence: (payload['confidence'] as num?)?.toDouble() ?? 0.0,
      degraded: payload['degraded'] as bool? ?? false,
      distanceRemainingMeters:
          (payload['distanceRemainingMeters'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// RouteRecalculatedEvent — rota recalculada. APP-5001.
class RouteRecalculatedEventDto {
  const RouteRecalculatedEventDto({
    this.totalDistanceMeters,
    this.totalDurationSeconds,
    this.waypointCount,
  });

  final int? totalDistanceMeters;
  final int? totalDurationSeconds;
  final int? waypointCount;

  factory RouteRecalculatedEventDto.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? json;
    return RouteRecalculatedEventDto(
      totalDistanceMeters: payload['totalDistanceMeters'] as int?,
      totalDurationSeconds: payload['totalDurationSeconds'] as int?,
      waypointCount: payload['waypointCount'] as int?,
    );
  }
}

/// DestinationReachedEvent — chegada ao destino. APP-5001.
class DestinationReachedEventDto {
  const DestinationReachedEventDto({
    this.distanceToDestinationMeters,
    this.totalElapsedSeconds,
  });

  final double? distanceToDestinationMeters;
  final int? totalElapsedSeconds;

  factory DestinationReachedEventDto.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? json;
    return DestinationReachedEventDto(
      distanceToDestinationMeters:
          (payload['distanceToDestinationMeters'] as num?)?.toDouble(),
      totalElapsedSeconds: payload['totalElapsedSeconds'] as int?,
    );
  }
}

/// Tipo de evento de rota para UI.
enum RouteTrackingEventType {
  etaUpdated,
  routeRecalculated,
  destinationReached,
}
