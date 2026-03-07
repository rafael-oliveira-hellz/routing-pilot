import 'package:flutter/material.dart';
import 'package:pilot_app/core/config/theme_mode_prefs.dart';
import 'package:pilot_app/core/di/injection.dart';

/// Notificador global do tema (claro/escuro/sistema). Persiste em ThemeModePrefs. APP-1008.
class ThemeModeNotifier extends ChangeNotifier {
  ThemeModeNotifier([ThemeModePrefs? prefs]) : _prefs = prefs ?? ThemeModePrefs();

  final ThemeModePrefs _prefs;
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get themeMode => _mode;

  Future<void> load() async {
    _mode = await _prefs.getThemeMode();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_mode == mode) return;
    await _prefs.setThemeMode(mode);
    _mode = mode;
    notifyListeners();
  }
}
