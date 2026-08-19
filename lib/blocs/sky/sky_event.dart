import 'package:equatable/equatable.dart';

import '../../models/device_orientation.dart';

sealed class SkyEvent extends Equatable {
  const SkyEvent();

  @override
  List<Object?> get props => [];
}

final class SkyLoadRequested extends SkyEvent {
  const SkyLoadRequested();
}

final class SkyPositionsUpdateRequested extends SkyEvent {
  const SkyPositionsUpdateRequested();
}

final class SkyOrientationChanged extends SkyEvent {
  final DeviceOrientation orientation;

  const SkyOrientationChanged(this.orientation);

  @override
  List<Object?> get props => [orientation];
}