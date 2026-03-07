import 'package:pilot_app/core/domain/dto/auth_dto.dart';

/// Contrato do repositório de autenticação.
abstract class AuthRepository {
  Future<LoginResponse> login(LoginRequest request);
  Future<void> register(RegisterRequest request);
  Future<bool> tryRestoreSession();

  /// Tenta refresh e persiste novos tokens. Usado pelo interceptor em 401.
  Future<bool> tryRefreshAndSave();

  Future<void> logout();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String token, String newPassword);
  Future<void> changePassword(String currentPassword, String newPassword);

  Future<UserResponse?> getCurrentUser();
  Future<bool> getRememberMe();
  Future<void> setRememberMe(bool value);
}
