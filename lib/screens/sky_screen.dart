import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/sky/sky_bloc.dart';
import '../blocs/sky/sky_event.dart';
import '../blocs/sky/sky_state.dart';
import '../services/constellation_service.dart';
import '../services/location_service.dart';
import '../services/orientation_service.dart';
import '../widgets/sky_painter.dart';
import '../services/star_catalog_service.dart';

class SkyScreen extends StatelessWidget {
  const SkyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SkyBloc(
        locationService: LocationService(),
        orientationService: OrientationService(),
        starCatalogService: StarCatalogService(),
        constellationService: ConstellationService(),
      )..add(const SkyLoadRequested()),
      child: const _SkyView(),
    );
  }
}

class _SkyView extends StatelessWidget {
  const _SkyView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SkyBloc, SkyState>(
      builder: (context, state) {
        switch (state.status) {
          case SkyStatus.initial:
          case SkyStatus.loading:
            return const _LoadingView();

          case SkyStatus.error:
            return _ErrorView(
              message: state.errorMessage ?? 'Something went wrong.',
            );

          case SkyStatus.loaded:
            return _LoadedView(state: state);
        }
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final SkyState state;

  const _LoadedView({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final orientation = state.orientation;

    if (orientation == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Waiting for sensors...',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomPaint(
          painter: SkyPainter(
            stars: state.stars,
            positions: state.positions,
            constellations: state.constellations,
            orientation: orientation,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}