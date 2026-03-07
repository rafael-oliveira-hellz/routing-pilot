import 'package:pilot_app/core/domain/dto/auth_dto.dart';
import 'package:pilot_app/core/security/remember_me_prefs.dart';
import 'package:pilot_app/core/security/secure_token_storage.dart';
import 'package:pilot_app/features/auth/domain/auth_repository.dart';

/// Mock AuthRepository para isMockEnabled. Não chama API; login sempre sucesso com usuário fake. APP-8003.
class AuthRepositoryMock implements AuthRepository {
  AuthRepositoryMock({
    required SecureTokenStorage storage,
    required RememberMePrefs rememberMePrefs,
  })  : _storage = storage,
        _rememberMePrefs = rememberMePrefs;

  final SecureTokenStorage _storage;
  final RememberMePrefs _rememberMePrefs;

  static const _fakeAccessToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsubCI6Im1vY2stdXNlciIsInZlaGljbGVfaWQiOiJtb2NrLXZlaGljbGUtMSIsInJvbGUiOiJEUklWRVIiLCJleHAiOjI5OTk5OTk5OTl9.x';
  static const _fakeRefreshToken = 'mock-refresh-token';
  static final _fakeUser = UserResponse(
    id: 'mock-user-id',
    email: 'mock@pilot.app',
    name: 'Usuário Mock',
    role: 'DRIVER',
    vehicleId: 'mock-vehicle-1',
  );

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    await _storage.saveTokens(
      accessToken: _fakeAccessToken,
      refreshToken: _fakeRefreshToken,
    );
    await _storage.saveUser(_fakeUser);
    await _rememberMePrefs.setRememberMe(request.rememberMe);
    return LoginResponse(
      accessToken: _fakeAccessToken,
      refreshToken: _fakeRefreshToken,
      expiresIn: 900,
      user: _fakeUser,
    );
  }

  @override
  Future<void> register(RegisterRequest request) async {}

  @override
  Future<bool> tryRestoreSession() async {
    final t = await _storage.getAccessToken();
    return t != null && t.isNotEmpty;
  }

  @override
  Future<bool> tryRefreshAndSave() async => true;

  @override
  Future<void> logout() async => await _storage.clearTokens();

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<void> resetPassword(String token, String newPassword) async {}

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {}

  @override
  Future<void> revokeAllOtherSessions() async {}

  @override
  Future<UserResponse?> getCurrentUser() async => _fakeUser;

  @override
  Future<bool> getRememberMe() async => _rememberMePrefs.getRememberMe();

  @override
  Future<void> setRememberMe(bool value) async =>
      _rememberMePrefs.setRememberMe(value);
}
