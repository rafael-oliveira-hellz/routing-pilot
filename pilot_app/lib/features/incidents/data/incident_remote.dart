import 'package:dio/dio.dart';
import 'package:pilot_app/core/domain/dto/incident_dto.dart';
import 'package:pilot_app/core/network/api_client.dart';

/// POST /api/v1/incidents, POST vote, GET /api/v1/incidents. APP-6001, APP-6002.
class IncidentRemote {
  IncidentRemote({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<ReportIncidentResponse> report(ReportIncidentRequest request) async {
    final r = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/v1/incidents',
      data: request.toJson(),
    );
    return ReportIncidentResponse.fromJson(r.data!);
  }

  Future<void> vote(String incidentId, VoteRequest request) async {
    await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/v1/incidents/$incidentId/vote',
      data: request.toJson(),
    );
  }

  Future<List<IncidentListItemDto>> listByLocation({
    required double lat,
    required double lon,
    required double radiusMeters,
  }) async {
    try {
      final r = await _apiClient.dio.get<dynamic>(
        '/api/v1/incidents',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'radius': radiusMeters,
        },
      );
      final list = r.data as List<dynamic>?;
      if (list == null) return [];
      return list
          .map((e) => IncidentListItemDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }
}
