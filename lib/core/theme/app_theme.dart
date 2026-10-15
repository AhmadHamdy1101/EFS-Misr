import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Light and dark themes for the whole app.
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.white,
    scaffoldBackgroundColor: AppColors.appBackground,
    cardColor: AppColors.white,
    colorScheme: const ColorScheme.light(
      primary: AppColors.black,
      tertiary: AppColors.lightGray,
      secondary: AppColors.green,
      brightness: Brightness.light,
      error: Colors.red,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onError: Colors.red,
      surface: AppColors.white,
      onSurface: AppColors.black,
    ),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),
    cardTheme: const CardThemeData(
      color: AppColors.white,
      shadowColor: AppColors.black,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.black),
      bodyMedium: TextStyle(color: AppColors.black),
      titleLarge: TextStyle(color: AppColors.black),
    ),
    buttonTheme: _buttonTheme(
      brightness: Brightness.light,
      primary: AppColors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
    ),
  );

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.scafolddark,
    scaffoldBackgroundColor: AppColors.scafolddark,
    cardColor: AppColors.black,
    shadowColor: AppColors.white,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.white,
      tertiary: AppColors.gray,
      secondary: AppColors.green,
      brightness: Brightness.dark,
      error: Colors.red,
      onPrimary: AppColors.green,
      onSecondary: AppColors.white,
      onError: Colors.red,
      surface: AppColors.buttondark,
      onSurface: AppColors.white,
    ),
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.scafolddark),
    cardTheme: CardThemeData(
      color: AppColors.buttondark,
      shadowColor: AppColors.white.withValues(alpha: 0.25),
    ),
    buttonTheme: _buttonTheme(
      brightness: Brightness.dark,
      primary: AppColors.buttondark,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
    ),
  );

  /// Both themes share the same button scheme except for the primary color.
  static ButtonThemeData _buttonTheme({
    required Brightness brightness,
    required Color primary,
  }) {
    const surface = Color(0xff1f2a3b);
    return ButtonThemeData(
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: primary,
        secondary: AppColors.green,
        onSecondary: AppColors.green,
        error: Colors.red,
        onError: Colors.red,
        surface: surface,
        onSurface: surface,
      ),
    );
  }
}
