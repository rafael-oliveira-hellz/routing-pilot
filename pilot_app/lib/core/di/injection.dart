import 'package:get_it/get_it.dart';
import 'package:pilot_app/core/network/api_client.dart';
import 'package:pilot_app/core/security/remember_me_prefs.dart';
import 'package:pilot_app/core/security/secure_token_storage.dart';
import 'package:pilot_app/features/auth/data/auth_remote.dart';
import 'package:pilot_app/features/auth/data/auth_repository_impl.dart';
import 'package:pilot_app/features/admin/data/admin_repository_impl.dart';
import 'package:pilot_app/features/admin/domain/admin_repository.dart';
import 'package:pilot_app/features/auth/domain/auth_repository.dart';

/// Registro de dependências (APIs, repositórios, use cases).
/// APP-1007: AdminRepository (GET/DELETE users).
/// Locator de dependências (GetIt). Nome explícito para injeção de serviços.
final GetIt serviceLocator = GetIt.instance;

Future<void> configureDependencies() async {
  serviceLocator.registerLazySingleton<SecureTokenStorage>(() => SecureTokenStorage());
  serviceLocator.registerLazySingleton<RememberMePrefs>(() => RememberMePrefs());
  serviceLocator.registerLazySingleton<AuthRemote>(() => AuthRemote());
  serviceLocator.registerLazySingleton<ApiClient>(() => ApiClient(
        getAccessToken: () => serviceLocator<SecureTokenStorage>().getAccessToken(),
        on401: () => serviceLocator<AuthRepository>().logout(),
        on401Retry: () => serviceLocator<AuthRepository>().tryRefreshAndSave(),
      ));
  serviceLocator.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remote: serviceLocator<AuthRemote>(),
        storage: serviceLocator<SecureTokenStorage>(),
        rememberMePrefs: serviceLocator<RememberMePrefs>(),
        apiClient: serviceLocator<ApiClient>(),
      ));
  serviceLocator.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(
        apiClient: serviceLocator<ApiClient>(),
      ));
}
