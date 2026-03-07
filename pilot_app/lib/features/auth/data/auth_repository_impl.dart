import 'package:dio/dio.dart';
import 'package:pilot_app/core/domain/dto/auth_dto.dart';
import 'package:pilot_app/core/network/api_client.dart';
import 'package:pilot_app/core/security/jwt_parser.dart';
import 'package:pilot_app/core/security/remember_me_prefs.dart';
import 'package:pilot_app/core/security/secure_token_storage.dart';
import 'package:pilot_app/features/auth/domain/auth_repository.dart';
import 'package:pilot_app/features/auth/data/auth_remote.dart';

/// Implementação: login/register/refresh persistem tokens e user; logout limpa.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemote remote,
    required SecureTokenStorage storage,
    required RememberMePrefs rememberMePrefs,
    required ApiClient apiClient,
  })  : _remote = remote,
        _storage = storage,
        _rememberMePrefs = rememberMePrefs,
        _apiClient = apiClient;

  final AuthRemote _remote;
  final SecureTokenStorage _storage;
  final RememberMePrefs _rememberMePrefs;
  final ApiClient _apiClient;

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _remote.login(request);
    await _storage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    await _storage.saveUser(response.user);
    await _rememberMePrefs.setRememberMe(request.rememberMe);
    return response;
  }

  @override
  Future<void> register(RegisterRequest request) async {
    await _remote.register(request);
  }

  @override
  Future<bool> tryRestoreSession() async {
    final access = await _storage.getAccessToken();
    final refresh = await _storage.getRefreshToken();

    if (access != null && access.isNotEmpty) {
      if (!JwtParser.isExpiredOrExpiringSoon(access, bufferSeconds: 300)) {
        return true;
      }
    }

    if (refresh != null && refresh.isNotEmpty) {
      try {
        final res = await _remote.refresh(refresh);
        await _storage.saveTokens(
          accessToken: res.accessToken,
          refreshToken: res.refreshToken,
        );
        if (res.user != null) await _storage.saveUser(res.user!);
        return true;
      } catch (_) {
        await _storage.clearTokens();
        return false;
      }
    }

    return false;
  }

  @override
  Future<bool> tryRefreshAndSave() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _remote.refresh(refresh);
      await _storage.saveTokens(
        accessToken: res.accessToken,
        refreshToken: res.refreshToken,
      );
      if (res.user != null) await _storage.saveUser(res.user!);
      return true;
    } catch (_) {
      await _storage.clearTokens();
      return false;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.dio.post<void>('/api/v1/auth/logout');
    } on DioException catch (_) {
      // Sempre limpa storage mesmo se o POST falhar
    }
    await _storage.clearTokens();
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _remote.forgotPassword(ForgotPasswordRequest(email: email));
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    await _remote.resetPassword(ResetPasswordRequest(
      token: token,
      newPassword: newPassword,
    ));
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _apiClient.dio.post<void>(
      '/api/v1/auth/change-password',
      data: ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ).toJson(),
    );
  }

  @override
  Future<void> revokeAllOtherSessions() async {
    final r = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/v1/auth/revoke-all-other-sessions',
    );
    final data = r.data;
    if (data != null &&
        data['refreshToken'] != null &&
        data['accessToken'] != null &&
        data['expiresIn'] != null) {
      final res = RefreshResponse.fromJson(data);
      await _storage.saveTokens(
        accessToken: res.accessToken,
        refreshToken: res.refreshToken,
      );
      if (res.user != null) await _storage.saveUser(res.user!);
    }
  }

  @override
  Future<UserResponse?> getCurrentUser() => _storage.getUser();

  @override
  Future<bool> getRememberMe() => _rememberMePrefs.getRememberMe();

  @override
  Future<void> setRememberMe(bool value) => _rememberMePrefs.setRememberMe(value);
}
