import 'package:dio/dio.dart';
import 'package:pilot_app/core/domain/dto/location_dto.dart';
import 'package:pilot_app/core/network/api_client.dart';

/// POST /api/v1/locations — batch de posições. 202 accepted; 429 com Retry-After; 5xx com backoff. APP-4001, APP-7002.
class LocationRemote {
  LocationRemote({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Retorna a resposta do batch; em 202 o body pode ser accepted/duplicates/rejected.
  /// Em 429: aguarda Retry-After e reenvia uma vez. Em 5xx: backoff e até 3 tentativas.
  Future<LocationsBatchResponse> sendBatch(LocationsBatchRequest request) async {
    int attempt = 0;
    const maxAttempts = 3;
    Duration backoff = const Duration(seconds: 1);
    while (true) {
      try {
        final r = await _apiClient.dio.post<Map<String, dynamic>>(
          '/api/v1/locations',
          data: request.toJson(),
        );
        if (r.statusCode == 202 && r.data != null) {
          return LocationsBatchResponse.fromJson(r.data!);
        }
        return const LocationsBatchResponse(accepted: 0);
      } on DioException catch (e) {
        attempt++;
        final status = e.response?.statusCode;
        if (status == 429 && attempt == 1) {
          final retryAfter = e.response?.headers.value('Retry-After');
          final seconds = int.tryParse(retryAfter ?? '') ?? 5;
          await Future.delayed(Duration(seconds: seconds));
          continue;
        }
        if (status != null && status >= 500 && attempt < maxAttempts) {
          await Future.delayed(backoff);
          backoff = Duration(milliseconds: backoff.inMilliseconds * 2);
          continue;
        }
        rethrow;
      }
    }
  }
}
