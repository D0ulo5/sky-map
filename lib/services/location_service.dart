import 'package:geolocator/geolocator.dart';

class LocationService {
  Position? _lastKnownPosition;

  Future<Position> getCurrentLocation() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationPermissionDeniedException();
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedForeverException();
    }

    // Try the cached location first.
    final lastKnown = await Geolocator.getLastKnownPosition();

    if (lastKnown != null) {
      _lastKnownPosition = lastKnown;
    }

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(
        const Duration(seconds: 5),
      );

      _lastKnownPosition = current;

      return current;
    } on Exception {
      if (_lastKnownPosition != null) {
        return _lastKnownPosition!;
      }

      rethrow;
    }
  }
}

class LocationServiceDisabledException implements Exception {}

class LocationPermissionDeniedException implements Exception {}

class LocationPermissionDeniedForeverException
    implements Exception {}