import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:pilot_app/core/config/app_config.dart';
import 'package:pilot_app/core/error/pilot_exception.dart';
import 'package:pilot_app/core/network/error_response.dart';
import 'package:pilot_app/core/security/certificate_pinning.dart';
import 'package:pilot_app/core/utils/trace_id.dart';

/// Cliente HTTP Dio com interceptors: Bearer, X-Trace-Id, timeout.
/// Em 401: tenta on401Retry (refresh); se sucesso reenvia a requisição; senão on401 (logout).
/// Tratamento de 429 (Retry-After), 503 (NetworkException). Não logar tokens.
/// Certificate pinning opcional via AppConfig.enableCertificatePinning e CERT_PIN_SHA256. APP-8002.
class ApiClient {
  ApiClient({
    required this.getAccessToken,
    Dio? dio,
    this.on401,
    this.on401Retry,
  }) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = AppConfig.baseUrl;
    _dio.options.connectTimeout = AppConfig.httpTimeout;
    _dio.options.receiveTimeout = AppConfig.httpTimeout;
    _dio.options.sendTimeout = AppConfig.httpTimeout;
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Accept'] = 'application/json';
    if (AppConfig.enableCertificatePinning && AppConfig.certificatePinSha256 != null) {
      _dio.httpClientAdapter = IOHttpClientAdapter(createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = validateCertificatePinning;
        return client;
      });
    }
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_traceIdInterceptor());
    _dio.interceptors.add(_errorInterceptor());
  }

  final Future<String?> Function() getAccessToken;
  final Future<void> Function()? on401;
  final Future<bool> Function()? on401Retry;

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
      onError: (error, handler) async {
        final response = error.response;
        if (response != null) {
          if (response.statusCode == 401 && on401Retry != null) {
            final ok = await on401Retry!();
            if (ok) {
              try {
                final res = await _dio.fetch(response.requestOptions);
                handler.resolve(res);
              } catch (e) {
                handler.reject(
                  e is DioException
                      ? e
                      : DioException(
                          requestOptions: response.requestOptions,
                          error: e,
                        ),
                );
              }
              return;
            }
            on401?.call();
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                error: AuthException(
                  'Sessão expirada',
                  'UNAUTHORIZED',
                  response.requestOptions.headers['X-Trace-Id'] as String?,
                ),
              ),
            );
            return;
          }
          if (response.statusCode == 401) {
            on401?.call();
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
          if (response.statusCode == 403) {
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                error: AuthException(
                  'Sem permissão',
                  'FORBIDDEN',
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
