class DeviceOrientation {
  /// Direction the back of the phone is facing.
  ///
  /// World coordinates:
  /// X = North
  /// Y = East
  /// Z = Up
  final double forwardX;
  final double forwardY;
  final double forwardZ;

  /// Direction toward the top edge of the screen.
  final double upX;
  final double upY;
  final double upZ;

  /// Direction toward the right edge of the screen.
  final double rightX;
  final double rightY;
  final double rightZ;

  /// Back-of-phone azimuth.
  final double azimuth;

  /// Back-of-phone altitude.
  final double altitude;

  const DeviceOrientation({
    required this.forwardX,
    required this.forwardY,
    required this.forwardZ,
    required this.upX,
    required this.upY,
    required this.upZ,
    required this.rightX,
    required this.rightY,
    required this.rightZ,
    required this.azimuth,
    required this.altitude,
  });
}