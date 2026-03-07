import 'package:shared_preferences/shared_preferences.dart';

/// Preferência "Lembrar de mim" (persistida em SharedPreferences).
class RememberMePrefs {
  RememberMePrefs({SharedPreferences? prefs}) : _prefs = prefs;
  SharedPreferences? _prefs;

  static const _keyRememberMe = 'pilot_remember_me';

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<bool> getRememberMe() async {
    return (await _instance).getBool(_keyRememberMe) ?? false;
  }

  Future<void> setRememberMe(bool value) async {
    await (await _instance).setBool(_keyRememberMe, value);
  }
}
