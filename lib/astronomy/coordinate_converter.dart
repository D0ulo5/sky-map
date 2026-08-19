import 'dart:math' as math;

import '../models/celestial_position.dart';
import '../models/sky_star.dart';

class CoordinateConverter {
  static CelestialPosition starToHorizontal({
    required SkyStar star,
    required double latitude,
    required double longitude,
    required DateTime utc,
  }) {
    final lst = _localSiderealTime(
      longitude: longitude,
      utc: utc,
    );

    var hourAngle = lst - star.ra;

    while (hourAngle < 0) {
      hourAngle += 360;
    }

    while (hourAngle >= 360) {
      hourAngle -= 360;
    }

    final h = _radians(hourAngle);
    final dec = _radians(star.dec);
    final lat = _radians(latitude);

    final sinAltitude =
        math.sin(dec) * math.sin(lat) +
        math.cos(dec) *
            math.cos(lat) *
            math.cos(h);

    final altitude = math.asin(
      sinAltitude.clamp(-1.0, 1.0),
    );

    /*
     * Azimuth:
     *
     * 0   = North
     * 90  = East
     * 180 = South
     * 270 = West
     */
    final y = math.sin(h);

    final x =
        math.cos(h) * math.sin(lat) -
        math.tan(dec) * math.cos(lat);

    var azimuth = math.atan2(y, x);

    azimuth += math.pi;

    var azimuthDegrees = _degrees(azimuth);

    azimuthDegrees %= 360;

    if (azimuthDegrees < 0) {
      azimuthDegrees += 360;
    }

    return CelestialPosition(
      azimuth: azimuthDegrees,
      altitude: _degrees(altitude),
    );
  }

  static double _localSiderealTime({
    required double longitude,
    required DateTime utc,
  }) {
    final jd = _julianDate(utc);

    final d = jd - 2451545.0;

    var gmst =
        280.46061837 +
        360.98564736629 * d;

    gmst %= 360;

    if (gmst < 0) {
      gmst += 360;
    }

    var lst = gmst + longitude;

    lst %= 360;

    if (lst < 0) {
      lst += 360;
    }

    return lst;
  }

  static double _julianDate(DateTime utc) {
    return utc.millisecondsSinceEpoch /
            86400000.0 +
        2440587.5;
  }

  static double _radians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  static double _degrees(double radians) {
    return radians * 180.0 / math.pi;
  }
}