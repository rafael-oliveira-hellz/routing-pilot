import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyThemeMode = 'pilot_theme_mode';

/// Persiste preferência de tema (claro/escuro/sistema). APP-1008.
class ThemeModePrefs {
  ThemeModePrefs([SharedPreferences? prefs]) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const ThemeMode _default = ThemeMode.system;

  Future<SharedPreferences> get _storage async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<ThemeMode> getThemeMode() async {
    final s = await _storage;
    final v = s.getString(_keyThemeMode);
    if (v == null) return _default;
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final s = await _storage;
    final v = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await s.setString(_keyThemeMode, v);
  }
}
