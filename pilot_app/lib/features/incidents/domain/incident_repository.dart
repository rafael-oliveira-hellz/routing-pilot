import 'package:pilot_app/core/domain/dto/incident_dto.dart';

/// Reportar, votar e listar incidentes. APP-6001, APP-6002.
abstract class IncidentRepository {
  Future<ReportIncidentResponse> report(ReportIncidentRequest request);
  Future<void> vote(String incidentId, VoteRequest request);
  Future<List<IncidentListItemDto>> listByLocation({
    required double lat,
    required double lon,
    required double radiusMeters,
  });
}
