import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/device_orientation.dart';

class HorizonPainter extends CustomPainter {
  final DeviceOrientation orientation;

  HorizonPainter({
    required this.orientation,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    /*
     * The horizon is the set of directions whose
     * altitude is exactly 0°.
     *
     * We sample the complete 360° horizon and project
     * those directions onto the screen.
     */

    final points = <Offset>[];

    for (var azimuth = 0.0;
        azimuth <= 360.0;
        azimuth += 2.0) {
      final point = _project(
        azimuth: azimuth,
        altitude: 0.0,
        center: center,
        size: size,
      );

      if (point != null) {
        points.add(point);
      }
    }

    if (points.length < 2) {
      return;
    }

    final paint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    path.moveTo(
      points.first.dx,
      points.first.dy,
    );

    for (var i = 1; i < points.length; i++) {
      path.lineTo(
        points[i].dx,
        points[i].dy,
      );
    }

    canvas.drawPath(path, paint);

    _drawCenterMarker(
      canvas,
      center,
    );
  }

  Offset? _project({
    required double azimuth,
    required double altitude,
    required Offset center,
    required Size size,
  }) {
    final azimuthRadians =
        azimuth * math.pi / 180;

    final altitudeRadians =
        altitude * math.pi / 180;

    /*
     * Convert astronomical coordinates into a world vector.
     *
     * X = North
     * Y = East
     * Z = Up
     */
    final worldX =
        math.cos(altitudeRadians) *
            math.cos(azimuthRadians);

    final worldY =
        math.cos(altitudeRadians) *
            math.sin(azimuthRadians);

    final worldZ =
        math.sin(altitudeRadians);

    /*
     * The orientation currently gives us the direction
     * of the back of the phone.
     *
     * For the first horizon implementation we use
     * azimuth and altitude as the camera center.
     */

    final cameraAzimuth =
        orientation.azimuth * math.pi / 180;

    final cameraAltitude =
        orientation.altitude * math.pi / 180;

    final cameraX =
        math.cos(cameraAltitude) *
            math.cos(cameraAzimuth);

    final cameraY =
        math.cos(cameraAltitude) *
            math.sin(cameraAzimuth);

    final cameraZ =
        math.sin(cameraAltitude);

    /*
     * Camera forward.
     */
    final forward = Vector3(
      cameraX,
      cameraY,
      cameraZ,
    );

    /*
     * World up.
     */
    const up = Vector3(
      0,
      0,
      1,
    );

    /*
     * Camera right = forward × up.
     */
    var right = forward.cross(up);

    if (right.length < 0.0001) {
      return null;
    }

    right = right.normalized();

    /*
     * Camera up = right × forward.
     */
    final cameraUp = right.cross(forward).normalized();

    /*
     * Convert world direction into camera space.
     */
    final x = Vector3(
      worldX,
      worldY,
      worldZ,
    ).dot(right);

    final y = Vector3(
      worldX,
      worldY,
      worldZ,
    ).dot(cameraUp);

    final z = Vector3(
      worldX,
      worldY,
      worldZ,
    ).dot(forward);

    /*
     * Don't render directions behind the camera.
     */
    if (z <= 0) {
      return null;
    }

    /*
     * Simple perspective projection.
     */
    final focalLength =
        size.height * 0.5;

    final screenX =
        center.dx -
        focalLength * x / z;

    final screenY =
        center.dy +
        focalLength * y / z;

    return Offset(
      screenX,
      screenY,
    );
  }

  void _drawCenterMarker(
    Canvas canvas,
    Offset center,
  ) {
    final paint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(center.dx - 8, center.dy),
      Offset(center.dx + 8, center.dy),
      paint,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - 8),
      Offset(center.dx, center.dy + 8),
      paint,
    );
  }

  @override
  bool shouldRepaint(
    HorizonPainter oldDelegate,
  ) {
    return oldDelegate.orientation != orientation;
  }
}

class Vector3 {
  final double x;
  final double y;
  final double z;

  const Vector3(
    this.x,
    this.y,
    this.z,
  );

  double get length {
    return math.sqrt(
      x * x +
          y * y +
          z * z,
    );
  }

  Vector3 normalized() {
    final value = length;

    if (value == 0) {
      return this;
    }

    return Vector3(
      x / value,
      y / value,
      z / value,
    );
  }

  Vector3 cross(Vector3 other) {
    return Vector3(
      y * other.z - z * other.y,
      z * other.x - x * other.z,
      x * other.y - y * other.x,
    );
  }

  double dot(Vector3 other) {
    return x * other.x +
        y * other.y +
        z * other.z;
  }
}