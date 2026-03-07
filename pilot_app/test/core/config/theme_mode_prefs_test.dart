import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pilot_app/core/config/theme_mode_prefs.dart';

void main() {
  group('ThemeModePrefs', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getThemeMode retorna system quando não definido', () async {
      final prefs = ThemeModePrefs(await SharedPreferences.getInstance());
      expect(await prefs.getThemeMode(), ThemeMode.system);
    });

    test('setThemeMode e getThemeMode refletem valor salvo', () async {
      final prefs = ThemeModePrefs(await SharedPreferences.getInstance());
      await prefs.setThemeMode(ThemeMode.light);
      expect(await prefs.getThemeMode(), ThemeMode.light);
      await prefs.setThemeMode(ThemeMode.dark);
      expect(await prefs.getThemeMode(), ThemeMode.dark);
      await prefs.setThemeMode(ThemeMode.system);
      expect(await prefs.getThemeMode(), ThemeMode.system);
    });
  });
}
