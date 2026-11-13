import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Shown instead of the camera preview when the scanner can't start.
Widget scannerError(BuildContext context, MobileScannerException error) {
  final message = switch (error.errorCode) {
    MobileScannerErrorCode.permissionDenied =>
      kIsWeb
          ? 'Camera access is blocked. Allow the camera for this site in the browser settings (it needs HTTPS).'
          : 'Camera access is denied. Allow it in the app settings to scan codes.',
    MobileScannerErrorCode.unsupported => 'No camera is available to scan.',
    _ => 'The camera could not start. Please try again.',
  };
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message.tr, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
