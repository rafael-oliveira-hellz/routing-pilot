import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pilot_app/core/domain/dto/auth_dto.dart';

/// Armazena access e refresh token e user básico de forma segura. Não logar valores.
class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  static const _keyAccessToken = 'pilot_access_token';
  static const _keyRefreshToken = 'pilot_refresh_token';
  static const _keyUser = 'pilot_user';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<void> saveUser(UserResponse user) async {
    await _storage.write(
      key: _keyUser,
      value: jsonEncode({
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'vehicleId': user.vehicleId,
        'role': user.role,
      }),
    );
  }

  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);

  Future<UserResponse?> getUser() async {
    final raw = await _storage.read(key: _keyUser);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserResponse.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUser);
  }
}
