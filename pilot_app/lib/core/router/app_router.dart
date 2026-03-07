import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilot_app/core/router/pages/home_placeholder_page.dart';
import 'package:pilot_app/core/router/pages/splash_page.dart';
import 'package:pilot_app/features/auth/presentation/pages/login_page.dart';
import 'package:pilot_app/features/auth/presentation/pages/register_page.dart';

/// Rotas nomeadas e deep links do Pilot App. APP-1004: splash, login, register.
class AppRouter {
  static const String routeSplash = 'splash';
  static const String routeHome = 'home';
  static const String routeLogin = 'login';
  static const String routeRegister = 'register';

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
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
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Página não encontrada: ${state.uri}'),
      ),
    ),
  );
}
