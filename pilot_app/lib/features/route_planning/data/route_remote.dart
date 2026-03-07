import 'package:pilot_app/core/domain/dto/route_dto.dart';
import 'package:pilot_app/core/network/api_client.dart';

/// POST /api/v1/route-requests. TraceId já enviado pelo ApiClient. APP-2001.
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
}
