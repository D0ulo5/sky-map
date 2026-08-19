import 'package:equatable/equatable.dart';

import '../../models/celestial_position.dart';
import '../../models/constellation.dart';
import '../../models/device_orientation.dart';
import '../../models/observer_location.dart';
import '../../models/sky_star.dart';

enum SkyStatus {
  initial,
  loading,
  loaded,
  error,
}

class SkyState extends Equatable {
  final SkyStatus status;

  final ObserverLocation? location;
  final DeviceOrientation? orientation;

  final List<SkyStar> stars;
  final List<Constellation> constellations;
  final List<CelestialPosition> positions;

  final DateTime? lastPositionUpdate;
  final String? errorMessage;

  const SkyState({
    this.status = SkyStatus.initial,
    this.location,
    this.orientation,
    this.stars = const [],
    this.constellations = const [],
    this.positions = const [],
    this.lastPositionUpdate,
    this.errorMessage,
  });

  SkyState copyWith({
    SkyStatus? status,
    ObserverLocation? location,
    DeviceOrientation? orientation,
    List<SkyStar>? stars,
    List<Constellation>? constellations,
    List<CelestialPosition>? positions,
    DateTime? lastPositionUpdate,
    String? errorMessage,
  }) {
    return SkyState(
      status: status ?? this.status,
      location: location ?? this.location,
      orientation: orientation ?? this.orientation,
      stars: stars ?? this.stars,
      constellations: constellations ?? this.constellations,
      positions: positions ?? this.positions,
      lastPositionUpdate:
          lastPositionUpdate ?? this.lastPositionUpdate,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        location,
        orientation,
        stars,
        constellations,
        positions,
        lastPositionUpdate,
        errorMessage,
      ];
}