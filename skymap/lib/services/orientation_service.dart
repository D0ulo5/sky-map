import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

class OrientationService {
  Stream<AccelerometerEvent> get accelerometer =>
      accelerometerEventStream();

  Stream<MagnetometerEvent> get magnetometer =>
      magnetometerEventStream();

  Stream<double> get heading {
    final controller = StreamController<double>();

    AccelerometerEvent? acceleration;
    MagnetometerEvent? magneticField;

    late final StreamSubscription<AccelerometerEvent> accelerometerSubscription;
    late final StreamSubscription<MagnetometerEvent> magnetometerSubscription;

    void calculateHeading() {
      if (acceleration == null || magneticField == null) {
        return;
      }

      final ax = acceleration!.x;
      final ay = acceleration!.y;
      final az = acceleration!.z;

      final mx = magneticField!.x;
      final my = magneticField!.y;
      final mz = magneticField!.z;

      final pitch = math.atan2(
        -ax,
        math.sqrt(ay * ay + az * az),
      );

      final roll = math.atan2(ay, az);

      final x = mx * math.cos(pitch) +
          mz * math.sin(pitch);

      final y = mx * math.sin(roll) * math.sin(pitch) +
          my * math.cos(roll) -
          mz * math.sin(roll) * math.cos(pitch);

      var heading = math.atan2(y, x) * 180 / math.pi;

      if (heading < 0) {
        heading += 360;
      }

      controller.add(heading);
    }

    accelerometerSubscription = accelerometer.listen((event) {
      acceleration = event;
      calculateHeading();
    });

    magnetometerSubscription = magnetometer.listen((event) {
      magneticField = event;
      calculateHeading();
    });

    controller.onCancel = () async {
      await accelerometerSubscription.cancel();
      await magnetometerSubscription.cancel();
    };

    return controller.stream;
  }
}