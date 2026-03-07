/// Exceção base do domínio Pilot. APP-1002.
class PilotException implements Exception {
  const PilotException(this.message, [this.code, this.traceId]);

  final String message;
  final String? code;
  final String? traceId;

  @override
  String toString() =>
      'PilotException: $message${code != null ? ' ($code)' : ''}';
}

/// Falha de autenticação (login, token, 401).
class AuthException extends PilotException {
  const AuthException(super.message, [super.code, super.traceId]);
}

/// Falha de rede (timeout, 5xx, sem conexão).
class NetworkException extends PilotException {
  const NetworkException(super.message, [super.code, super.traceId]);
}

/// Falha de validação (campos inválidos, 4xx).
class ValidationException extends PilotException {
  const ValidationException(super.message, [super.code, super.traceId]);
}
