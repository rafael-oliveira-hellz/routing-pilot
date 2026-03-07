import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilot_app/core/router/pages/home_placeholder_page.dart';
import 'package:pilot_app/features/auth/presentation/pages/placeholder_login_page.dart';

/// Rotas nomeadas e deep links do Pilot App.
/// Expandido nos cards de auth (login, register, forgot-password, etc.).
class AppRouter {
  static const String routeHome = 'home';
  static const String routeLogin = 'login';

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: routeHome,
        builder: (_, __) => const HomePlaceholderPage(),
      ),
      GoRoute(
        path: '/login',
        name: routeLogin,
        builder: (_, __) => const PlaceholderLoginPage(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Página não encontrada: ${state.uri}'),
      ),
    ),
  );
}
