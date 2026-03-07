import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilot_app/core/router/pages/home_placeholder_page.dart';
import 'package:pilot_app/core/router/pages/splash_page.dart';
import 'package:pilot_app/features/auth/presentation/pages/change_password_page.dart';
import 'package:pilot_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:pilot_app/features/auth/presentation/pages/login_page.dart';
import 'package:pilot_app/features/auth/presentation/pages/register_page.dart';
import 'package:pilot_app/features/auth/presentation/pages/reset_password_page.dart';

/// Rotas nomeadas e deep links do Pilot App. APP-1005: forgot/reset/change password.
class AppRouter {
  static const String routeSplash = 'splash';
  static const String routeHome = 'home';
  static const String routeLogin = 'login';
  static const String routeRegister = 'register';
  static const String routeForgotPassword = 'forgot-password';
  static const String routeResetPassword = 'reset-password';
  static const String routeChangePassword = 'change-password';

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
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Página não encontrada: ${state.uri}'),
      ),
    ),
  );
}
