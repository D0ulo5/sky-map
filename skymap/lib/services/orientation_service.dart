import 'package:sensors_plus/sensors_plus.dart';

class OrientationService {
  Stream<MagnetometerEvent> get magnetometer =>
      magnetometerEventStream();
}