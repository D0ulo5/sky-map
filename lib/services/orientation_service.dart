import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import '../models/device_orientation.dart';

class OrientationService {
  static const Duration updateInterval = Duration(milliseconds: 50);

  final StreamController<DeviceOrientation> _controller =
      StreamController<DeviceOrientation>.broadcast();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  Timer? _updateTimer;

  List<double>? _gravity;
  List<double>? _magneticField;

  bool _running = false;

  Stream<DeviceOrientation> get orientationStream => _controller.stream;

  void start() {
    if (_running) {
      return;
    }

    _running = true;

    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: updateInterval,
    ).listen(_onAccelerometer);

    _magnetometerSubscription = magnetometerEventStream(
      samplingPeriod: updateInterval,
    ).listen(_onMagnetometer);

    _updateTimer = Timer.periodic(
      updateInterval,
      (_) => _calculateAndEmit(),
    );
  }

  void _onAccelerometer(AccelerometerEvent event) {
    _gravity = [
      event.x,
      event.y,
      event.z,
    ];
  }

  void _onMagnetometer(MagnetometerEvent event) {
    _magneticField = [
      event.x,
      event.y,
      event.z,
    ];
  }

  void _calculateAndEmit() {
    final gravity = _gravity;
    final magneticField = _magneticField;

    if (gravity == null || magneticField == null) {
      return;
    }

    final orientation = _calculateOrientation(
      gravity,
      magneticField,
    );

    if (orientation != null) {
      _controller.add(orientation);
    }
  }

  DeviceOrientation? _calculateOrientation(
    List<double> gravity,
    List<double> magneticField,
  ) {
    final gravityLength = _length(
      gravity[0],
      gravity[1],
      gravity[2],
    );

    final magneticLength = _length(
      magneticField[0],
      magneticField[1],
      magneticField[2],
    );

    if (gravityLength < 0.1 || magneticLength < 0.1) {
      return null;
    }

    /*
     * Gravity points toward the ground.
     */
    final gx = gravity[0] / gravityLength;
    final gy = gravity[1] / gravityLength;
    final gz = gravity[2] / gravityLength;

    /*
     * Normalize the magnetic field.
     */
    final mx = magneticField[0] / magneticLength;
    final my = magneticField[1] / magneticLength;
    final mz = magneticField[2] / magneticLength;

    /*
     * Build the horizontal East vector.
     *
     * East = Magnetic × Gravity
     */
    var eastX = my * gz - mz * gy;
    var eastY = mz * gx - mx * gz;
    var eastZ = mx * gy - my * gx;

    final eastLength = _length(
      eastX,
      eastY,
      eastZ,
    );

    if (eastLength < 0.1) {
      return null;
    }

    eastX /= eastLength;
    eastY /= eastLength;
    eastZ /= eastLength;

    /*
     * North = Gravity × East
     */
    var northX = gy * eastZ - gz * eastY;
    var northY = gz * eastX - gx * eastZ;
    var northZ = gx * eastY - gy * eastX;

    final northLength = _length(
      northX,
      northY,
      northZ,
    );

    if (northLength < 0.1) {
      return null;
    }

    northX /= northLength;
    northY /= northLength;
    northZ /= northLength;

    /*
     * Up is opposite gravity.
     */
    final upX = -gx;
    final upY = -gy;
    final upZ = -gz;

    /*
     * IMPORTANT:
     *
     * The sky map looks in the direction the BACK
     * of the phone faces.
     *
     * Android's Z axis points toward the back of
     * the device, away from the screen.
     */
    const deviceForwardX = 0.0;
    const deviceForwardY = 0.0;
    const deviceForwardZ = -1.0;

    /*
     * Transform the phone's back direction into
     * North / East / Up coordinates.
     */
    final northComponent =
        deviceForwardX * northX +
        deviceForwardY * northY +
        deviceForwardZ * northZ;

    final eastComponent =
        deviceForwardX * eastX +
        deviceForwardY * eastY +
        deviceForwardZ * eastZ;

    final upComponent =
        deviceForwardX * upX +
        deviceForwardY * upY +
        deviceForwardZ * upZ;

    /*
     * Forward vector expressed as:
     *
     * X = North
     * Y = East
     * Z = Up
     */
    final forwardX = northComponent;
    final forwardY = eastComponent;
    final forwardZ = upComponent;

    /*
     * Horizontal direction.
     */
    final azimuth = math.atan2(
      eastComponent,
      northComponent,
    );

    /*
     * Vertical direction.
     */
    final horizontalLength = math.sqrt(
      northComponent * northComponent +
          eastComponent * eastComponent,
    );

    final altitude = math.atan2(
      upComponent,
      horizontalLength,
    );

    return DeviceOrientation(
      azimuth: _normalizeDegrees(
        _toDegrees(azimuth),
      ),
      altitude: _toDegrees(altitude),
      forwardX: forwardX,
      forwardY: forwardY,
      forwardZ: forwardZ,
    );
  }

  double _length(
    double x,
    double y,
    double z,
  ) {
    return math.sqrt(
      x * x +
          y * y +
          z * z,
    );
  }

  double _toDegrees(double radians) {
    return radians * 180 / math.pi;
  }

  double _normalizeDegrees(double degrees) {
    final normalized = degrees % 360;

    if (normalized < 0) {
      return normalized + 360;
    }

    return normalized;
  }

  Future<void> stop() async {
    if (!_running) {
      return;
    }

    _running = false;

    _updateTimer?.cancel();
    _updateTimer = null;

    await _accelerometerSubscription?.cancel();
    await _magnetometerSubscription?.cancel();

    _accelerometerSubscription = null;
    _magnetometerSubscription = null;

    _gravity = null;
    _magneticField = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}