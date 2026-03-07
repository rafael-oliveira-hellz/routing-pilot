import 'package:pilot_app/core/domain/dto/auth_dto.dart';
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
  })  : _remote = remote,
        _storage = storage,
        _rememberMePrefs = rememberMePrefs;

  final AuthRemote _remote;
  final SecureTokenStorage _storage;
  final RememberMePrefs _rememberMePrefs;

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
    final rememberMe = await _rememberMePrefs.getRememberMe();

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
  Future<void> logout() async {
    await _storage.clearTokens();
  }

  @override
  Future<UserResponse?> getCurrentUser() => _storage.getUser();

  @override
  Future<bool> getRememberMe() => _rememberMePrefs.getRememberMe();

  @override
  Future<void> setRememberMe(bool value) => _rememberMePrefs.setRememberMe(value);
}
