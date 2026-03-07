import 'package:dio/dio.dart';
import 'package:pilot_app/core/config/app_config.dart';
import 'package:pilot_app/core/domain/dto/auth_dto.dart';
import 'package:pilot_app/core/utils/trace_id.dart';

/// Chamadas HTTP de auth (login, refresh, register) sem Bearer.
/// Usa Dio próprio com baseUrl, timeout e X-Trace-Id.
class AuthRemote {
  AuthRemote({Dio? dio}) : _dio = dio ?? _createDio();

  final Dio _dio;

  static Dio _createDio() {
    final d = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.httpTimeout,
      receiveTimeout: AppConfig.httpTimeout,
      sendTimeout: AppConfig.httpTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    d.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['X-Trace-Id'] = generateTraceId();
        handler.next(options);
      },
    ));
    return d;
  }

  Future<LoginResponse> login(LoginRequest request) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      data: request.toJson(),
    );
    return LoginResponse.fromJson(r.data!);
  }

  Future<RefreshResponse> refresh(String refreshToken) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return RefreshResponse.fromJson(r.data!);
  }

  Future<void> register(RegisterRequest request) async {
    await _dio.post<void>(
      '/api/v1/users',
      data: request.toJson(),
    );
  }

  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    await _dio.post<void>(
      '/api/v1/auth/forgot-password',
      data: request.toJson(),
    );
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    await _dio.post<void>(
      '/api/v1/auth/reset-password',
      data: request.toJson(),
    );
  }
}
