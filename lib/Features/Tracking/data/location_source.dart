import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repo/tracking_repo.dart';

/// Whether the app may read the device location right now.
enum LocationAccess {
  granted,

  /// Granted, but only approximate location (Android/iOS "precise" off).
  approximate,
  denied,

  /// Denied with "don't ask again"; only the system settings can fix it.
  deniedForever,
  serviceDisabled,
}

/// Device location, behind an interface so the cubit can be tested.
abstract interface class LocationSource {
  Future<LocationAccess> checkAccess();

  /// Asks the OS for foreground ("while in use") permission if needed.
  Future<LocationAccess> requestAccess();

  Future<LocationFix?> currentFix();

  /// Positions while sharing. Errors when permission is revoked or location
  /// services are turned off.
  Stream<LocationFix> watch();

  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}

class GeolocatorLocationSource implements LocationSource {
  /// Readings closer than this to the previous one are not delivered, which
  /// keeps GPS jitter of a parked phone from turning into traffic.
  static const distanceFilterMeters = 20;

  @override
  Future<LocationAccess> checkAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    return _accessFor(await Geolocator.checkPermission());
  }

  @override
  Future<LocationAccess> requestAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return _accessFor(permission);
  }

  Future<LocationAccess> _accessFor(LocationPermission permission) async {
    switch (permission) {
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationAccess.denied;
      case LocationPermission.deniedForever:
        return LocationAccess.deniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        if (kIsWeb) return LocationAccess.granted;
        final accuracy = await Geolocator.getLocationAccuracy();
        return accuracy == LocationAccuracyStatus.reduced
            ? LocationAccess.approximate
            : LocationAccess.granted;
    }
  }

  @override
  Future<LocationFix?> currentFix() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return _fix(position);
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      return last == null ? null : _fix(last);
    }
  }

  @override
  Stream<LocationFix> watch() {
    return Geolocator.getPositionStream(
      locationSettings: _settings(),
    ).map(_fix);
  }

  /// On Android the stream runs inside a foreground service with a visible
  /// notification, so updates continue while the app is in the background
  /// or the screen is locked (no background-location permission needed,
  /// because sharing is always started from the foreground). On iOS the
  /// "location" background mode keeps a stream started in the foreground
  /// alive and shows the blue status-bar indicator.
  LocationSettings _settings() {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      );
    }
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'EFS is sharing your location',
          notificationText: 'Administrators can see your live location.',
          notificationChannelName: 'Live location',
          setOngoing: true,
        ),
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
        activityType: ActivityType.automotiveNavigation,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilterMeters,
    );
  }

  LocationFix _fix(Position position) => LocationFix(
    latitude: position.latitude,
    longitude: position.longitude,
    recordedAt: position.timestamp,
    accuracy: position.accuracy,
    heading: position.heading >= 0 ? position.heading : null,
    speed: position.speed >= 0 ? position.speed : null,
  );

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}

/// A random id for this installation. A session is bound to the device that
/// accepted it, so a second phone signed into the same account can't publish
/// competing positions.
class DeviceIdStore {
  DeviceIdStore(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'tracking_device_id';

  String get deviceId {
    final existing = _prefs.getString(_key);
    if (existing != null) return existing;
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    _prefs.setString(_key, id);
    return id;
  }
}
