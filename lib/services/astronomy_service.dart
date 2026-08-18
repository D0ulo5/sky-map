import 'dart:math' as math;

import 'location_service.dart';

class SkyPosition {
  final double azimuth;
  final double altitude;

  const SkyPosition({
    required this.azimuth,
    required this.altitude,
  });
}

class AstronomyService {
  Future<SkyPosition> getStarPosition({
    required double rightAscension,
    required double declination,
    required LocationService locationService,
    DateTime? time,
  }) async {
    final location = await locationService.getCurrentLocation();

    return equatorialToHorizontal(
      rightAscension: rightAscension,
      declination: declination,
      latitude: location.latitude,
      longitude: location.longitude,
      time: time ?? DateTime.now(),
    );
  }

  SkyPosition equatorialToHorizontal({
    required double rightAscension,
    required double declination,
    required double latitude,
    required double longitude,
    required DateTime time,
  }) {
    final lst = _localSiderealTime(
      longitude: longitude,
      time: time,
    );

    final hourAngle = _normalizeDegrees(
      lst - rightAscension,
    );

    final latitudeRadians = _toRadians(latitude);
    final declinationRadians = _toRadians(declination);
    final hourAngleRadians = _toRadians(hourAngle);

    final sinAltitude =
        math.sin(latitudeRadians) *
            math.sin(declinationRadians) +
        math.cos(latitudeRadians) *
            math.cos(declinationRadians) *
            math.cos(hourAngleRadians);

    final altitude = math.asin(
      sinAltitude.clamp(-1.0, 1.0),
    );

    final azimuth = math.atan2(
      math.sin(hourAngleRadians),
      math.cos(hourAngleRadians) *
              math.sin(latitudeRadians) -
          math.tan(declinationRadians) *
              math.cos(latitudeRadians),
    );

    return SkyPosition(
      azimuth: _normalizeDegrees(
        _toDegrees(azimuth) + 180,
      ),
      altitude: _toDegrees(altitude),
    );
  }

  double _localSiderealTime({
    required double longitude,
    required DateTime time,
  }) {
    final utc = time.toUtc();

    final jd = _julianDate(utc);
    final d = jd - 2451545.0;

    final gmst =
        280.46061837 +
        360.98564736629 * d;

    return _normalizeDegrees(
      gmst + longitude,
    );
  }

  double _julianDate(DateTime time) {
    return time.millisecondsSinceEpoch / 86400000 +
        2440587.5;
  }

  double _normalizeDegrees(double value) {
    value %= 360;

    if (value < 0) {
      value += 360;
    }

    return value;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  double _toDegrees(double radians) {
    return radians * 180 / math.pi;
  }
}