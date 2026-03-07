/// Exceção base do domínio Pilot.
/// Sprint 1: hierarquia AuthException, NetworkException, ValidationException.
class PilotException implements Exception {
  const PilotException(this.message, [this.code, this.traceId]);

  final String message;
  final String? code;
  final String? traceId;

  @override
  String toString() => 'PilotException: $message${code != null ? ' ($code)' : ''}';
}
