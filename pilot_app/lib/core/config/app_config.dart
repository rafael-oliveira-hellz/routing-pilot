import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Ambiente da aplicação (local, dev, staging, prod).
enum AppEnv {
  /// Backend rodando na máquina (localhost / emulador). Use BASE_URL no .env.
  local,
  dev,
  staging,
  prod,
}

/// Configuração global do app (env, base URL, timeouts, constantes GPS).
/// Carrega .env via flutter_dotenv; fallback para --dart-define se necessário.
class AppConfig {
  static bool _initialized = false;

  /// Padrão para backend no host: emulador Android usa 10.0.2.2; iOS/Chrome usam localhost (ajuste no .env).
  static const String _defaultLocalBaseUrl = 'http://10.0.2.2:8080';

  static String get baseUrl => _baseUrl;
  static String _baseUrl = 'https://api.pilot.example.com';

  /// URL base para WebSocket (ws/wss conforme baseUrl). Sprint 4.
  static String get wsBaseUrl {
    final b = _baseUrl;
    if (b.startsWith('https://')) return b.replaceFirst('https://', 'wss://');
    if (b.startsWith('http://')) return b.replaceFirst('http://', 'ws://');
    return 'wss://$_baseUrl';
  }

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

  /// Centro padrão do mapa (lat/lon). Usado quando não há polyline ou posição do usuário.
  static double get mapCenterLat => 0.0;
  static double get mapCenterLon => 0.0;

  /// Opcional: chave Google Maps se no futuro quiser usar tiles Google. Hoje o app usa OpenStreetMap (gratuito, sem chave).
  static String? get googleMapsApiKey => _googleMapsApiKey;
  static String? _googleMapsApiKey;

  static bool get hasGoogleMapsApiKey =>
      _googleMapsApiKey != null && _googleMapsApiKey!.trim().isNotEmpty;

  /// Quando true, usar mocks em vez da API real (login, rotas, etc.). APP-8003.
  static bool get isMockEnabled => _isMockEnabled;
  static bool _isMockEnabled = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      await dotenv.load(fileName: '.env');
      final envStr = dotenv.env['ENV']?.toLowerCase() ?? 'local';
      _env = switch (envStr) {
        'local' => AppEnv.local,
        'staging' => AppEnv.staging,
        'prod' || 'production' => AppEnv.prod,
        _ => AppEnv.dev,
      };
      _baseUrl = dotenv.env['BASE_URL'] ??
          (_env == AppEnv.local ? _defaultLocalBaseUrl : _baseUrl);
      _googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY']?.trim();
      _isMockEnabled = dotenv.env['isMockEnabled']?.toLowerCase() == 'true';
    } catch (_) {
      // .env ausente: usar local com default para rodar localmente
      _env = AppEnv.local;
      _baseUrl = _defaultLocalBaseUrl;
    }
    _initialized = true;
  }
}
