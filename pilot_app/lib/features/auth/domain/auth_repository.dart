import 'package:pilot_app/core/domain/dto/auth_dto.dart';

/// Contrato do repositório de autenticação.
abstract class AuthRepository {
  Future<LoginResponse> login(LoginRequest request);
  Future<void> register(RegisterRequest request);
  Future<bool> tryRestoreSession();
  Future<void> logout();
  Future<UserResponse?> getCurrentUser();
  Future<bool> getRememberMe();
  Future<void> setRememberMe(bool value);
}
