import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../astronomy/coordinate_converter.dart';
import '../../models/celestial_position.dart';
import '../../services/constellation_service.dart';
import '../../services/location_service.dart';
import '../../services/orientation_service.dart';
import '../../services/star_catalog_service.dart';

import 'sky_event.dart';
import 'sky_state.dart';

class SkyBloc extends Bloc<SkyEvent, SkyState> {
  final LocationService locationService;
  final OrientationService orientationService;
  final StarCatalogService starCatalogService;
  final ConstellationService constellationService;

  StreamSubscription? _orientationSubscription;
  Timer? _positionTimer;

  SkyBloc({
    required this.locationService,
    required this.orientationService,
    required this.starCatalogService,
    required this.constellationService,
  }) : super(const SkyState()) {
    on<SkyLoadRequested>(_onLoadRequested);
    on<SkyPositionsUpdateRequested>(
      _onPositionsUpdateRequested,
    );
    on<SkyOrientationChanged>(_onOrientationChanged);
  }

  Future<void> _onLoadRequested(
    SkyLoadRequested event,
    Emitter<SkyState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SkyStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      final stars =
          await starCatalogService.loadStars();

      final constellations =
          await constellationService.loadConstellations();

      final location =
          await locationService.getCurrentLocation();

      final positions = _calculatePositions(
        stars: stars,
        location: location,
        utc: DateTime.now().toUtc(),
      );

      emit(
        state.copyWith(
          status: SkyStatus.loaded,
          stars: stars,
          constellations: constellations,
          location: location,
          positions: positions,
          lastPositionUpdate: DateTime.now().toUtc(),
        ),
      );

      _startOrientation();
      _startPositionTimer();
    } catch (error) {
      emit(
        state.copyWith(
          status: SkyStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onPositionsUpdateRequested(
    SkyPositionsUpdateRequested event,
    Emitter<SkyState> emit,
  ) async {
    final location = state.location;

    if (state.status != SkyStatus.loaded ||
        location == null) {
      return;
    }

    final utc = DateTime.now().toUtc();

    final positions = _calculatePositions(
      stars: state.stars,
      location: location,
      utc: utc,
    );

    emit(
      state.copyWith(
        positions: positions,
        lastPositionUpdate: utc,
      ),
    );
  }

  void _onOrientationChanged(
    SkyOrientationChanged event,
    Emitter<SkyState> emit,
  ) {
    emit(
      state.copyWith(
        orientation: event.orientation,
      ),
    );
  }

  List<CelestialPosition> _calculatePositions({
    required List stars,
    required dynamic location,
    required DateTime utc,
  }) {
    return stars.map<CelestialPosition>((star) {
      return CoordinateConverter.starToHorizontal(
        star: star,
        latitude: location.latitude,
        longitude: location.longitude,
        utc: utc,
      );
    }).toList();
  }

  void _startOrientation() {
    _orientationSubscription?.cancel();

    orientationService.start();

    _orientationSubscription =
        orientationService.orientationStream.listen(
      (orientation) {
        add(
          SkyOrientationChanged(orientation),
        );
      },
    );
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();

    _positionTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        add(
          const SkyPositionsUpdateRequested(),
        );
      },
    );
  }

  @override
  Future<void> close() async {
    _positionTimer?.cancel();

    await _orientationSubscription?.cancel();

    await orientationService.dispose();

    return super.close();
  }
}