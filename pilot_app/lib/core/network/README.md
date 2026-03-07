# core/network

- **ApiClient**: Dio com baseUrl/timeout do AppConfig; interceptors: Bearer (access token), X-Trace-Id (UUID v4), Content-Type.
- **ErrorResponse**: tipagem de erros (timestamp, status, errorCode, message, path, traceId).
- Tratamento: 401 → AuthException (refresh/logout no auth); 429 → Retry-After; 503/5xx → backoff; 4xx → ValidationException.
