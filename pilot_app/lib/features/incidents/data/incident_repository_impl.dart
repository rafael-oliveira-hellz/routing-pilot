import 'package:pilot_app/core/domain/dto/incident_dto.dart';
import 'package:pilot_app/features/incidents/domain/incident_repository.dart';
import 'package:pilot_app/features/incidents/data/incident_remote.dart';

class IncidentRepositoryImpl implements IncidentRepository {
  IncidentRepositoryImpl({required IncidentRemote remote}) : _remote = remote;

  final IncidentRemote _remote;

  @override
  Future<ReportIncidentResponse> report(ReportIncidentRequest request) =>
      _remote.report(request);

  @override
  Future<void> vote(String incidentId, VoteRequest request) =>
      _remote.vote(incidentId, request);

  @override
  Future<List<IncidentListItemDto>> listByLocation({
    required double lat,
    required double lon,
    required double radiusMeters,
  }) =>
      _remote.listByLocation(
        lat: lat,
        lon: lon,
        radiusMeters: radiusMeters,
      );
}
