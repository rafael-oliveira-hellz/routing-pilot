import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/core/router/pages/home_placeholder_page.dart';
import 'package:pilot_app/core/router/pages/splash_page.dart';
import 'package:pilot_app/features/auth/domain/auth_repository.dart';
import 'package:pilot_app/features/auth/presentation/pages/change_password_page.dart';
import 'package:pilot_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:pilot_app/features/auth/presentation/pages/login_page.dart';
import 'package:pilot_app/features/auth/presentation/pages/register_page.dart';
import 'package:pilot_app/features/auth/presentation/pages/reset_password_page.dart';
import 'package:pilot_app/features/auth/presentation/pages/security_page.dart';
import 'package:pilot_app/features/admin/presentation/pages/admin_users_page.dart';
import 'package:pilot_app/features/route_planning/presentation/pages/new_route_page.dart';
import 'package:pilot_app/features/route_planning/presentation/pages/route_map_page.dart';
import 'package:pilot_app/features/tracking/presentation/pages/en_rota_page.dart';
import 'package:pilot_app/features/incidents/presentation/pages/report_incident_page.dart';
import 'package:pilot_app/features/incidents/presentation/pages/incidents_list_page.dart';
import 'package:pilot_app/core/router/pages/error_page.dart';
import 'package:pilot_app/features/route_planning/presentation/pages/route_result_page.dart';

/// Rotas nomeadas e deep links do Pilot App. APP-2002: routes/new, routes/result. APP-3001: routes/map.
class AppRouter {
  static const String routeSplash = 'splash';
  static const String routeHome = 'home';
  static const String routeLogin = 'login';
  static const String routeRegister = 'register';
  static const String routeForgotPassword = 'forgot-password';
  static const String routeResetPassword = 'reset-password';
  static const String routeChangePassword = 'change-password';
  static const String routeSecurity = 'security';
  static const String routeAdminUsers = 'admin-users';
  static const String routeNewRoute = 'new-route';
  static const String routeRouteResult = 'route-result';
  static const String routeMap = 'route-map';
  static const String routeEnRota = 'en-rota';
  static const String routeReportIncident = 'report-incident';
  static const String routeIncidentsList = 'incidents-list';
  static const String routeError = 'error';

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) async {
      final location = state.matchedLocation;
      if (location == '/admin/users') {
        final user = await serviceLocator<AuthRepository>().getCurrentUser();
        if (user == null || !user.isAdmin) return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: routeSplash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: '/',
        name: routeHome,
        builder: (_, __) => const HomePlaceholderPage(),
      ),
      GoRoute(
        path: '/login',
        name: routeLogin,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: routeRegister,
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: routeForgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        name: routeResetPassword,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordPage(token: token);
        },
      ),
      GoRoute(
        path: '/change-password',
        name: routeChangePassword,
        builder: (_, __) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/security',
        name: routeSecurity,
        builder: (_, __) => const SecurityPage(),
      ),
      GoRoute(
        path: '/admin/users',
        name: routeAdminUsers,
        builder: (_, __) => const AdminUsersPage(),
      ),
      GoRoute(
        path: '/routes/new',
        name: routeNewRoute,
        builder: (_, __) => const NewRoutePage(),
      ),
      GoRoute(
        path: '/routes/result',
        name: routeRouteResult,
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          final status = state.uri.queryParameters['status'] ?? '';
          return RouteResultPage(requestId: id, status: status);
        },
      ),
      GoRoute(
        path: '/routes/map',
        name: routeMap,
        builder: (context, state) {
          final requestId = state.uri.queryParameters['requestId'];
          final args = state.extra as RouteMapArgs?;
          return RouteMapPage(requestId: requestId, args: args);
        },
      ),
      GoRoute(
        path: '/routes/en-rota',
        name: routeEnRota,
        builder: (context, state) {
          final requestId = state.uri.queryParameters['requestId'] ?? '';
          final args = state.extra as EnRotaArgs?;
          return EnRotaPage(
            routeRequestId: requestId,
            initialPolyline: args?.polyline,
          );
        },
      ),
      GoRoute(
        path: '/incidents/report',
        name: routeReportIncident,
        builder: (_, __) => const ReportIncidentPage(),
      ),
      GoRoute(
        path: '/incidents',
        name: routeIncidentsList,
        builder: (_, __) => const IncidentsListPage(),
      ),
      GoRoute(
        path: '/error',
        name: routeError,
        builder: (context, state) {
          final message = state.uri.queryParameters['message'] ?? 'Algo deu errado.';
          final traceId = state.uri.queryParameters['traceId'];
          return ErrorPage(message: message, traceId: traceId);
        },
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Página não encontrada: ${state.uri}'),
      ),
    ),
  );
}
