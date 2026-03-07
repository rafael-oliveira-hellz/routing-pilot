import 'package:get_it/get_it.dart';
import 'package:pilot_app/core/network/api_client.dart';
import 'package:pilot_app/core/security/remember_me_prefs.dart';
import 'package:pilot_app/core/security/secure_token_storage.dart';
import 'package:pilot_app/features/auth/data/auth_remote.dart';
import 'package:pilot_app/features/auth/data/auth_repository_impl.dart';
import 'package:pilot_app/features/auth/domain/auth_repository.dart';

/// Registro de dependências (APIs, repositórios, use cases).
/// APP-1005: ApiClient antes de AuthRepository (on401Retry usa repo); logout POST + refresh em 401.
final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl.registerLazySingleton<SecureTokenStorage>(() => SecureTokenStorage());
  sl.registerLazySingleton<RememberMePrefs>(() => RememberMePrefs());
  sl.registerLazySingleton<AuthRemote>(() => AuthRemote());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(
        getAccessToken: () => sl<SecureTokenStorage>().getAccessToken(),
        on401: () => sl<AuthRepository>().logout(),
        on401Retry: () => sl<AuthRepository>().tryRefreshAndSave(),
      ));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remote: sl<AuthRemote>(),
        storage: sl<SecureTokenStorage>(),
        rememberMePrefs: sl<RememberMePrefs>(),
        apiClient: sl<ApiClient>(),
      ));
}
