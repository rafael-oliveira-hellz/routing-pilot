import 'package:get_it/get_it.dart';
import 'package:pilot_app/core/config/theme_mode_notifier.dart';
import 'package:pilot_app/core/config/theme_mode_prefs.dart';
import 'package:pilot_app/core/network/api_client.dart';
import 'package:pilot_app/core/security/remember_me_prefs.dart';
import 'package:pilot_app/core/security/secure_token_storage.dart';
import 'package:pilot_app/features/auth/data/auth_remote.dart';
import 'package:pilot_app/core/config/app_config.dart';
import 'package:pilot_app/features/auth/data/auth_repository_impl.dart';
import 'package:pilot_app/features/auth/data/auth_repository_mock.dart';
import 'package:pilot_app/features/admin/data/admin_repository_impl.dart';
import 'package:pilot_app/features/admin/domain/admin_repository.dart';
import 'package:pilot_app/features/auth/domain/auth_repository.dart';
import 'package:pilot_app/features/route_planning/data/route_remote.dart';
import 'package:pilot_app/features/route_planning/data/route_repository_impl.dart';
import 'package:pilot_app/features/route_planning/domain/route_repository.dart';
import 'package:pilot_app/features/tracking/data/eta_ws_client.dart';
import 'package:pilot_app/features/tracking/data/location_remote.dart';
import 'package:pilot_app/features/tracking/data/location_service.dart';
import 'package:pilot_app/features/tracking/data/offline_location_buffer.dart';
import 'package:pilot_app/features/incidents/data/incident_remote.dart';
import 'package:pilot_app/features/incidents/data/incident_repository_impl.dart';
import 'package:pilot_app/features/incidents/data/incident_ws_client.dart';
import 'package:pilot_app/features/incidents/domain/incident_repository.dart';

/// Registro de dependências (APIs, repositórios, use cases).
/// APP-2001: RouteRepository (POST route-requests).
/// Locator de dependências (GetIt). Nome explícito para injeção de serviços.
final GetIt serviceLocator = GetIt.instance;

Future<void> configureDependencies() async {
  serviceLocator.registerLazySingleton<ThemeModePrefs>(() => ThemeModePrefs());
  serviceLocator.registerLazySingleton<ThemeModeNotifier>(() => ThemeModeNotifier(
        serviceLocator<ThemeModePrefs>(),
      ));
  serviceLocator.registerLazySingleton<SecureTokenStorage>(() => SecureTokenStorage());
  serviceLocator.registerLazySingleton<RememberMePrefs>(() => RememberMePrefs());
  serviceLocator.registerLazySingleton<AuthRemote>(() => AuthRemote());
  serviceLocator.registerLazySingleton<ApiClient>(() => ApiClient(
        getAccessToken: () => serviceLocator<SecureTokenStorage>().getAccessToken(),
        on401: () => serviceLocator<AuthRepository>().logout(),
        on401Retry: () => serviceLocator<AuthRepository>().tryRefreshAndSave(),
      ));
  if (AppConfig.isMockEnabled) {
    serviceLocator.registerLazySingleton<AuthRepository>(() => AuthRepositoryMock(
          storage: serviceLocator<SecureTokenStorage>(),
          rememberMePrefs: serviceLocator<RememberMePrefs>(),
        ));
  } else {
    serviceLocator.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
          remote: serviceLocator<AuthRemote>(),
          storage: serviceLocator<SecureTokenStorage>(),
          rememberMePrefs: serviceLocator<RememberMePrefs>(),
          apiClient: serviceLocator<ApiClient>(),
        ));
  }
  serviceLocator.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(
        apiClient: serviceLocator<ApiClient>(),
      ));
  serviceLocator.registerLazySingleton<RouteRemote>(() => RouteRemote(
        apiClient: serviceLocator<ApiClient>(),
      ));
  serviceLocator.registerLazySingleton<RouteRepository>(() => RouteRepositoryImpl(
        remote: serviceLocator<RouteRemote>(),
      ));
  // Sprint 4: tracking (GPS batch + WebSocket ETA)
  serviceLocator.registerLazySingleton<LocationRemote>(() => LocationRemote(
        apiClient: serviceLocator<ApiClient>(),
      ));
  serviceLocator.registerLazySingleton<OfflineLocationBuffer>(() => OfflineLocationBuffer());
  serviceLocator.registerLazySingleton<LocationService>(() => LocationService(
        remote: serviceLocator<LocationRemote>(),
        offlineBuffer: serviceLocator<OfflineLocationBuffer>(),
      ));
  serviceLocator.registerLazySingleton<EtaWsClient>(() => EtaWsClient(
        getAccessToken: () => serviceLocator<SecureTokenStorage>().getAccessToken(),
      ));
  // Sprint 6: incidentes
  serviceLocator.registerLazySingleton<IncidentRemote>(() => IncidentRemote(
        apiClient: serviceLocator<ApiClient>(),
      ));
  serviceLocator.registerLazySingleton<IncidentRepository>(() => IncidentRepositoryImpl(
        remote: serviceLocator<IncidentRemote>(),
      ));
  serviceLocator.registerLazySingleton<IncidentWsClient>(() => IncidentWsClient(
        getAccessToken: () => serviceLocator<SecureTokenStorage>().getAccessToken(),
      ));
}
