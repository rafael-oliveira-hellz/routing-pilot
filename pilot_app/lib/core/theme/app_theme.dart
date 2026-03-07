import 'package:flutter/material.dart';

/// Tema do Pilot App (Material 3).
/// Sprint 1: ajustar cores e tipografia conforme design.
class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1565C0),
        brightness: Brightness.light,
        primary: const Color(0xFF1565C0),
      ),
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
        seedColor: const Color(0xFF42A5F5),
        brightness: Brightness.dark,
        primary: const Color(0xFF42A5F5),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
