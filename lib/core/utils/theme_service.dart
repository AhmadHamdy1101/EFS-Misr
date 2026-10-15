import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the theme and language choices between launches.
class ThemeService {
  ThemeService(this._prefs);

  static const _themeKey = 'themeMode';
  static const _localeKey = 'locale';

  final SharedPreferences _prefs;

  ThemeMode get themeMode => switch (_prefs.getString(_themeKey)) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => ThemeMode.system,
  };

  Locale get locale => Locale(_prefs.getString(_localeKey) ?? 'en');

  Future<void> switchTheme(ThemeMode mode) async {
    Get.changeThemeMode(mode);
    await _prefs.setString(_themeKey, mode.name);
  }

  Future<void> switchLocale(Locale locale) async {
    await Get.updateLocale(locale);
    await _prefs.setString(_localeKey, locale.languageCode);
  }
}
