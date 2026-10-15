import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Shows a floating snackbar. Widgets call this in response to a cubit
/// result instead of cubits showing UI themselves.
void showAppSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  bool isError = false,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppColors.white)),
        backgroundColor: isError ? Colors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
