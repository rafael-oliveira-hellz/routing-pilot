import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Ambiente da aplicação (dev, staging, prod).
enum AppEnv {
  dev,
  staging,
  prod,
}

/// Configuração global do app (env, base URL, timeouts, constantes GPS).
/// Carrega .env via flutter_dotenv; fallback para --dart-define se necessário.
class AppConfig {
  static bool _initialized = false;

  static String get baseUrl => _baseUrl;
  static String _baseUrl = 'https://api.pilot.example.com';

  static AppEnv get env => _env;
  static AppEnv _env = AppEnv.dev;

  /// Timeout das requisições HTTP (alinhado ao backend).
  static Duration get httpTimeout => const Duration(seconds: 30);

  /// Delay entre tentativas de reconexão WebSocket.
  static Duration get wsReconnectDelay => const Duration(seconds: 2);

  /// Tamanho máximo de payload por request (backend: 100 KB).
  static int get maxPayloadBytes => 100 * 1024;

  /// Número máximo de tentativas de retry em falha de rede/5xx.
  static int get maxRetryAttempts => 3;

  /// Base do backoff entre retries (ex.: 1s, 2s, 4s).
  static Duration get retryBackoffBase => const Duration(seconds: 1);

  // --- Constantes de envio GPS (doc 05) ---

  /// Batch: no máximo 10 posições ou 5 s (o que vier primeiro).
  static int get locationBatchMaxSize => 10;
  static Duration get locationBatchMaxWait => const Duration(seconds: 5);

  /// Intervalo em movimento normal (3–5 s).
  static Duration get locationIntervalNormal => const Duration(seconds: 4);

  /// Intervalo em curva/desvio (1 s).
  static Duration get locationIntervalCurve => const Duration(seconds: 1);

  /// Intervalo com veículo parado (speed < 1 m/s) (10 s).
  static Duration get locationIntervalStopped => const Duration(seconds: 10);

  /// Heartbeat sem movimento > 2 min (30 s).
  static Duration get locationIntervalHeartbeat => const Duration(seconds: 30);

  /// Buffer offline: máximo de posições (~3 h a 1/s).
  static int get offlineBufferMaxSize => 10_000;

  /// Ao atingir esta fração do buffer, remover mais antigas (FIFO).
  static double get offlineBufferTrimRatio => 0.9;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      await dotenv.load(fileName: '.env');
      _baseUrl = dotenv.env['BASE_URL'] ?? _baseUrl;
      final envStr = dotenv.env['ENV']?.toLowerCase() ?? 'dev';
      _env = switch (envStr) {
        'staging' => AppEnv.staging,
        'prod' || 'production' => AppEnv.prod,
        _ => AppEnv.dev,
      };
    } catch (_) {
      // .env ausente ou inválido: manter defaults (baseUrl, dev)
    }
    _initialized = true;
  }
}
