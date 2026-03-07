import 'package:dio/dio.dart';
import 'package:pilot_app/core/config/app_config.dart';
import 'package:pilot_app/core/error/pilot_exception.dart';
import 'package:pilot_app/core/network/error_response.dart';
import 'package:pilot_app/core/utils/trace_id.dart';

/// Cliente HTTP Dio com interceptors: Bearer, X-Trace-Id, timeout.
/// Tratamento de 401 (AuthException), 429 (Retry-After), 503 (NetworkException).
/// Não logar tokens nem corpo de resposta com dados sensíveis.
class ApiClient {
  ApiClient({
    required this.getAccessToken,
    Dio? dio,
    this.on401,
  }) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = AppConfig.baseUrl;
    _dio.options.connectTimeout = AppConfig.httpTimeout;
    _dio.options.receiveTimeout = AppConfig.httpTimeout;
    _dio.options.sendTimeout = AppConfig.httpTimeout;
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Accept'] = 'application/json';
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_traceIdInterceptor());
    _dio.interceptors.add(_errorInterceptor());
  }

  final Future<String?> Function() getAccessToken;
  final Future<void> Function()? on401;

  final Dio _dio;
  String? _currentTraceId;

  Dio get dio => _dio;

  String? get currentTraceId => _currentTraceId;

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    );
  }

  InterceptorsWrapper _traceIdInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        _currentTraceId = generateTraceId();
        options.headers['X-Trace-Id'] = _currentTraceId;
        handler.next(options);
      },
    );
  }

  InterceptorsWrapper _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        final response = error.response;
        if (response != null) {
          if (response.statusCode == 401) {
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                error: AuthException(
                  'Não autorizado',
                  'UNAUTHORIZED',
                  response.requestOptions.headers['X-Trace-Id'] as String?,
                ),
              ),
            );
            return;
          }
          if (response.statusCode == 429) {
            final retryAfter = response.headers.value('Retry-After');
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                error: NetworkException(
                  'Limite de requisições. ${retryAfter != null ? 'Tente novamente em ${retryAfter}s' : ''}'.trim(),
                  'RATE_LIMITED',
                  response.requestOptions.headers['X-Trace-Id'] as String?,
                ),
              ),
            );
            return;
          }
          if (response.statusCode != null && response.statusCode! >= 500) {
            ErrorResponse? errResp;
            try {
              final data = response.data;
              if (data is Map<String, dynamic>) {
                errResp = ErrorResponse.fromJson(data);
              }
            } catch (_) {}
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                error: NetworkException(
                  errResp?.message ?? 'Erro no servidor',
                  errResp?.errorCode ?? 'SERVER_ERROR',
                  errResp?.traceId ?? response.requestOptions.headers['X-Trace-Id'] as String?,
                ),
              ),
            );
            return;
          }
          try {
            final data = response.data;
            if (data is Map<String, dynamic>) {
              final errResp = ErrorResponse.fromJson(data);
              handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  error: ValidationException(
                    errResp.message ?? 'Erro de validação',
                    errResp.errorCode,
                    errResp.traceId,
                  ),
                ),
              );
              return;
            }
          } catch (_) {}
        }
        handler.next(error);
      },
    );
  }
}
