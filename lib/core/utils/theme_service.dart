// lib/core/utils/theme_service.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const _key = 'themeMode';

  ThemeMode get theme => _loadThemeFromBox();

  ThemeMode _loadThemeFromBox() {
    final box = Get.find<SharedPreferences>();
    final themeText = box.getString(_key) ?? 'light';
    return themeText == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> switchTheme(ThemeMode mode) async {
    final box = Get.find<SharedPreferences>();
    await box.setString(_key, mode == ThemeMode.dark ? 'dark' : 'light');
    Get.changeThemeMode(mode);
  }
}
