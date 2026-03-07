import 'package:dio/dio.dart';
import 'package:pilot_app/core/domain/dto/route_dto.dart';
import 'package:pilot_app/core/network/api_client.dart';

/// POST /api/v1/route-requests. GET result e POST recalc. APP-2001, APP-3002.
class RouteRemote {
  RouteRemote({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<RouteRequestResponse> submitRouteRequest(RouteRequestDto request) async {
    final r = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/v1/route-requests',
      data: request.toJson(),
    );
    return RouteRequestResponse.fromJson(r.data!);
  }

  /// GET /api/v1/route-requests/{id}/result. Retorna null se 404 (resultado ainda não disponível).
  Future<RouteResultDto?> getRouteResult(String routeRequestId) async {
    try {
      final r = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/route-requests/$routeRequestId/result',
      );
      if (r.data == null) return null;
      return RouteResultDto.fromJson(r.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// POST /api/v1/route-requests/{id}/recalculate — reason: MANUAL, ROUTE_DEVIATION, etc.
  Future<void> requestRecalculation(String routeRequestId, String reason) async {
    await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/v1/route-requests/$routeRequestId/recalculate',
      data: {'reason': reason},
    );
  }
}
