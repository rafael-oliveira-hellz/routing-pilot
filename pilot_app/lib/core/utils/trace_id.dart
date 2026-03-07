import 'package:uuid/uuid.dart';

/// Geração e uso de traceId (UUID v4) para correlação com o backend.
/// Header X-Trace-Id em todas as requisições.
const _uuid = Uuid();

String generateTraceId() => _uuid.v4();
