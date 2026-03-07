/// Resposta de erro do backend (4xx/5xx). Doc 14 checklist.
class ErrorResponse {
  const ErrorResponse({
    required this.timestamp,
    required this.status,
    this.errorCode,
    this.message,
    this.path,
    this.traceId,
  });

  final DateTime timestamp;
  final int status;
  final String? errorCode;
  final String? message;
  final String? path;
  final String? traceId;

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as int? ?? 0,
      errorCode: json['errorCode'] as String?,
      message: json['message'] as String?,
      path: json['path'] as String?,
      traceId: json['traceId'] as String?,
    );
  }
}
