import 'package:flutter/material.dart';

/// Tema do Pilot App (Material 3). APP-1008: claro/escuro, contraste WCAG, tipografia escalável.
class AppTheme {
  static const Color _seedLight = Color(0xFF1565C0);
  static const Color _seedDark = Color(0xFF42A5F5);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedLight,
        brightness: Brightness.light,
        primary: _seedLight,
      ),
      textTheme: _textTheme(Brightness.light),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedDark,
        brightness: Brightness.dark,
        primary: _seedDark,
      ),
      textTheme: _textTheme(Brightness.dark),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  /// Tipografia base Material 3; texto respeita MediaQuery.textScalerOf (acessibilidade).
  static TextTheme _textTheme(Brightness brightness) {
    final base = Typography.material2021(
      englishLike: Typography.englishLike2021,
      black: Typography.blackMountainView,
    );
    final textTheme = brightness == Brightness.dark ? base.white : base.black;
    return textTheme.copyWith(
      bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16),
      bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 14),
      bodySmall: textTheme.bodySmall?.copyWith(fontSize: 12),
      labelLarge: textTheme.labelLarge?.copyWith(fontSize: 14),
    );
  }
}
