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

  // Display controls.
  final bool showHorizon;
  final bool showConstellations;
  final bool objectSelectionEnabled;

  // Transient: which star is currently selected, if any. Independent
  // of showConstellations — selecting a star reveals its constellation
  // for as long as it's selected, regardless of that setting.
  final int? selectedStarId;

  const SkyState({
    this.status = SkyStatus.initial,
    this.location,
    this.orientation,
    this.stars = const [],
    this.constellations = const [],
    this.positions = const [],
    this.lastPositionUpdate,
    this.errorMessage,
    this.showHorizon = true,
    this.showConstellations = true,
    this.objectSelectionEnabled = false,
    this.selectedStarId,
  });

  SkyStar? get selectedStar {
    if (selectedStarId == null) {
      return null;
    }

    for (final star in stars) {
      if (star.id == selectedStarId) {
        return star;
      }
    }

    return null;
  }

  Constellation? get selectedConstellation {
    final star = selectedStar;

    if (star == null || star.constellation == null) {
      return null;
    }

    for (final constellation in constellations) {
      if (constellation.id == star.constellation) {
        return constellation;
      }
    }

    return null;
  }

  SkyState copyWith({
    SkyStatus? status,
    ObserverLocation? location,
    DeviceOrientation? orientation,
    List<SkyStar>? stars,
    List<Constellation>? constellations,
    List<CelestialPosition>? positions,
    DateTime? lastPositionUpdate,
    String? errorMessage,
    bool? showHorizon,
    bool? showConstellations,
    bool? objectSelectionEnabled,
    int? selectedStarId,
    bool clearSelection = false,
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
      showHorizon:
          showHorizon ?? this.showHorizon,
      showConstellations:
          showConstellations ?? this.showConstellations,
      objectSelectionEnabled:
          objectSelectionEnabled ??
              this.objectSelectionEnabled,
      selectedStarId: clearSelection
          ? null
          : (selectedStarId ?? this.selectedStarId),
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
        showHorizon,
        showConstellations,
        objectSelectionEnabled,
        selectedStarId,
      ];
}