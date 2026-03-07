/// Configuração global do app (env, base URL, timeouts).
/// Sprint 1: carregar via flutter_dotenv ou --dart-define.
class AppConfig {
  static bool _initialized = false;

  static String get baseUrl => _baseUrl;
  static final String _baseUrl = 'https://api.pilot.example.com';

  static Duration get httpTimeout => const Duration(seconds: 30);
  static Duration get wsReconnectDelay => const Duration(seconds: 2);
  static int get locationBatchMaxSize => 10;
  static Duration get locationBatchMaxWait => const Duration(seconds: 5);
  static int get offlineBufferMaxSize => 10_000;
  static double get offlineBufferTrimRatio => 0.9;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    // TODO: carregar .env ou dart-define (BASE_URL, ENV)
    _initialized = true;
  }
}
