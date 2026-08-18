import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

class OrientationService {
  OrientationService() {
    _startSensors();
  }

  final StreamController<double> _headingController =
      StreamController<double>.broadcast();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  List<double>? _accelerometer;
  List<double>? _magnetometer;

  Stream<double> get heading => _headingController.stream;

  void _startSensors() {
    _accelerometerSubscription =
        accelerometerEventStream().listen((event) {
      _accelerometer = [
        event.x,
        event.y,
        event.z,
      ];

      _updateHeading();
    });

    _magnetometerSubscription =
        magnetometerEventStream().listen((event) {
      _magnetometer = [
        event.x,
        event.y,
        event.z,
      ];

      _updateHeading();
    });
  }

  void _updateHeading() {
    final accelerometer = _accelerometer;
    final magnetometer = _magnetometer;

    if (accelerometer == null || magnetometer == null) {
      return;
    }

    final heading = _calculateHeading(
      accelerometer,
      magnetometer,
    );

    if (heading == null) {
      return;
    }

    _headingController.add(heading);
  }

  double? _calculateHeading(
    List<double> accelerometer,
    List<double> magnetometer,
  ) {
    final ax = accelerometer[0];
    final ay = accelerometer[1];
    final az = accelerometer[2];

    final mx = magnetometer[0];
    final my = magnetometer[1];
    final mz = magnetometer[2];

    final accelerationMagnitude =
        math.sqrt(ax * ax + ay * ay + az * az);

    if (accelerationMagnitude == 0) {
      return null;
    }

    final magneticMagnitude =
        math.sqrt(mx * mx + my * my + mz * mz);

    if (magneticMagnitude == 0) {
      return null;
    }

    final nx = ax / accelerationMagnitude;
    final ny = ay / accelerationMagnitude;
    final nz = az / accelerationMagnitude;

    final mxn = mx / magneticMagnitude;
    final myn = my / magneticMagnitude;
    final mzn = mz / magneticMagnitude;

    final hx = myn * nz - mzn * ny;
    final hy = mzn * nx - mxn * nz;

    if (hx == 0 && hy == 0) {
      return null;
    }

    var heading = math.atan2(hy, hx) * 180 / math.pi;

    if (heading < 0) {
      heading += 360;
    }

    return heading;
  }

  Future<void> dispose() async {
    await _accelerometerSubscription?.cancel();
    await _magnetometerSubscription?.cancel();
    await _headingController.close();
  }
}