import 'dart:convert';

/// Leitura de claims do JWT (exp, sub, vehicle_id, role). Não valida assinatura (confiamos no backend).
/// Não logar o token nem os claims sensíveis.
class JwtParser {
  /// Retorna payload decodificado ou null se inválido.
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final padded = payload.padRight(payload.length + (4 - payload.length % 4) % 4, '=');
      final decoded = utf8.decode(base64Url.decode(padded));
      return jsonDecode(decoded) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  static int? getExpirationSecondsSinceEpoch(String token) {
    final payload = decodePayload(token);
    if (payload == null) return null;
    final exp = payload['exp'];
    if (exp is int) return exp;
    if (exp is num) return exp.toInt();
    return null;
  }

  /// True se o token expira em menos de [bufferSeconds] (ex.: 5 min).
  static bool isExpiredOrExpiringSoon(String token, {int bufferSeconds = 300}) {
    final exp = getExpirationSecondsSinceEpoch(token);
    if (exp == null) return true;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return exp <= now + bufferSeconds;
  }

  static String? getSubject(String token) {
    final payload = decodePayload(token);
    return payload?['sub'] as String?;
  }

  static String? getVehicleId(String token) {
    final payload = decodePayload(token);
    return payload?['vehicle_id'] as String? ?? payload?['vehicleId'] as String?;
  }

  static String? getRole(String token) {
    final payload = decodePayload(token);
    return payload?['role'] as String?;
  }
}
