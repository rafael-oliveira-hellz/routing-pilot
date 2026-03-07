/// DTOs para API e eventos de incidentes. APP-6001, APP-6002.

class ReportIncidentRequest {
  const ReportIncidentRequest({
    required this.lat,
    required this.lon,
    required this.incidentType,
    this.severity,
    this.description,
    required this.reportedBy,
  });

  final double lat;
  final double lon;
  final String incidentType;
  final String? severity;
  final String? description;
  final String reportedBy;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'incidentType': incidentType,
        if (severity != null) 'severity': severity,
        if (description != null && description!.isNotEmpty) 'description': description,
        'reportedBy': reportedBy,
      };
}

class ReportIncidentResponse {
  const ReportIncidentResponse({required this.incidentId});

  final String incidentId;

  factory ReportIncidentResponse.fromJson(Map<String, dynamic> json) {
    return ReportIncidentResponse(
      incidentId: json['incidentId'] as String,
    );
  }
}

class VoteRequest {
  const VoteRequest({required this.voteType});

  final String voteType; // CONFIRM, DENY, GONE

  Map<String, dynamic> toJson() => {'voteType': voteType};
}

class IncidentListItemDto {
  const IncidentListItemDto({
    required this.id,
    required this.lat,
    required this.lon,
    required this.incidentType,
    this.severity,
    this.description,
    this.expiresAt,
    this.radiusMeters,
    this.distanceMeters,
  });

  final String id;
  final double lat;
  final double lon;
  final String incidentType;
  final String? severity;
  final String? description;
  final DateTime? expiresAt;
  final int? radiusMeters;
  final double? distanceMeters;

  factory IncidentListItemDto.fromJson(Map<String, dynamic> json) {
    return IncidentListItemDto(
      id: json['id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      incidentType: json['incidentType'] as String,
      severity: json['severity'] as String?,
      description: json['description'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      radiusMeters: json['radiusMeters'] as int?,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
    );
  }
}

/// IncidentActivatedEvent payload. APP-6002.
class IncidentActivatedEventDto {
  const IncidentActivatedEventDto({
    required this.incidentId,
    required this.incidentType,
    required this.severity,
    required this.lat,
    required this.lon,
    this.radiusMeters,
    this.expiresAt,
  });

  final String incidentId;
  final String incidentType;
  final String severity;
  final double lat;
  final double lon;
  final int? radiusMeters;
  final DateTime? expiresAt;

  factory IncidentActivatedEventDto.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? json;
    return IncidentActivatedEventDto(
      incidentId: payload['incidentId'] as String,
      incidentType: payload['incidentType'] as String,
      severity: payload['severity'] as String,
      lat: (payload['lat'] as num).toDouble(),
      lon: (payload['lon'] as num).toDouble(),
      radiusMeters: payload['radiusMeters'] as int?,
      expiresAt: payload['expiresAt'] != null
          ? DateTime.tryParse(payload['expiresAt'] as String)
          : null,
    );
  }
}

/// IncidentExpiredEvent payload. APP-6002.
class IncidentExpiredEventDto {
  const IncidentExpiredEventDto({required this.incidentId});

  final String incidentId;

  factory IncidentExpiredEventDto.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? json;
    return IncidentExpiredEventDto(
      incidentId: payload['incidentId'] as String,
    );
  }
}
