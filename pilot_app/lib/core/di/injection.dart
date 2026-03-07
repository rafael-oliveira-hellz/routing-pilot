import 'package:get_it/get_it.dart';
import 'package:pilot_app/core/network/api_client.dart';
import 'package:pilot_app/core/security/secure_token_storage.dart';

/// Registro de dependências (APIs, repositórios, use cases).
/// APP-1003: SecureTokenStorage, ApiClient (Dio + interceptors).
final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl.registerLazySingleton<SecureTokenStorage>(() => SecureTokenStorage());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(
        getAccessToken: () => sl<SecureTokenStorage>().getAccessToken(),
        on401: null, // APP-1004: registrar callback de refresh/logout
      ));
}
