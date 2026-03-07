import 'package:get_it/get_it.dart';

/// Registro de dependências (APIs, repositórios, use cases).
/// Expandido nos cards seguintes (auth, network, etc.).
final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  // Rotas e navegação são configurados em app_router.dart
  // Repositórios e use cases serão registrados em APP-1003 (rede) e APP-1004 (auth)
}
