// DTOs de request/response para APIs de auth. Sprint 1.

class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  final String email;
  final String password;
  final bool rememberMe;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'rememberMe': rememberMe,
      };
}

class UserResponse {
  const UserResponse({
    required this.id,
    required this.email,
    required this.name,
    this.vehicleId,
    required this.role,
  });

  final String id;
  final String email;
  final String name;
  final String? vehicleId;
  final String role;

  /// Papéis: USER e ADMIN. APP-1007.
  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      vehicleId: json['vehicleId'] as String?,
      role: json['role'] as String? ?? 'USER',
    );
  }
}

/// Item da lista de usuários (admin). GET /api/v1/users.
class UserListItemDto {
  const UserListItemDto({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.active = true,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final bool active;

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory UserListItemDto.fromJson(Map<String, dynamic> json) {
    return UserListItemDto(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'USER',
      active: json['active'] as bool? ?? true,
    );
  }
}

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserResponse user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      user: UserResponse.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Resposta de POST /api/v1/auth/refresh (user opcional).
class RefreshResponse {
  const RefreshResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserResponse? user;

  factory RefreshResponse.fromJson(Map<String, dynamic> json) {
    return RefreshResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      user: json['user'] != null
          ? UserResponse.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Map<String, dynamic> toJson() => {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };
}

class ForgotPasswordRequest {
  const ForgotPasswordRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}

class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.token,
    required this.newPassword,
  });

  final String token;
  final String newPassword;

  Map<String, dynamic> toJson() => {
        'token': token,
        'newPassword': newPassword,
      };
}

/// Request para POST /api/v1/users (cadastro).
class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.password,
    required this.name,
  });

  final String email;
  final String password;
  final String name;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'name': name,
      };
}
