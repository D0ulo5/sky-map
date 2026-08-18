import 'package:flutter/material.dart';

import '../models/star.dart';
import '../services/astronomy_service.dart';
import '../services/location_service.dart';
import '../services/star_catalog_service.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _locationService = LocationService();
  final _astronomyService = AstronomyService();
  final _catalogService = StarCatalogService();

  String _status = 'Ready';

  Star? _star;
  double? _altitude;
  double? _azimuth;

  Future<void> _calculateStarPosition() async {
    setState(() {
      _status = 'Loading star catalog...';
      _altitude = null;
      _azimuth = null;
    });

    try {
      final stars = await _catalogService.loadStars();

      final alpheratz = stars.firstWhere(
        (star) => star.commonName == 'Alpheratz',
      );

      setState(() {
        _star = alpheratz;
        _status = 'Getting location...';
      });

      final position =
          await _astronomyService.getStarPosition(
        rightAscension: alpheratz.ra,
        declination: alpheratz.dec,
        locationService: _locationService,
      );

      if (!mounted) return;

      setState(() {
        _altitude = position.altitude;
        _azimuth = position.azimuth;
        _status = 'Position calculated';
      });
    } on LocationServiceDisabledException {
      setState(() {
        _status = 'Location services are disabled.';
      });
    } on LocationPermissionDeniedException {
      setState(() {
        _status = 'Location permission was denied.';
      });
    } on LocationPermissionDeniedForeverException {
      setState(() {
        _status =
            'Location permission was permanently denied.';
      });
    } catch (error) {
      setState(() {
        _status = 'Error: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sky Map',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                if (_star != null) ...[
                  Text(
                    _star!.commonName ?? _star!.name ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Altitude: ${_altitude?.toStringAsFixed(2)}°',
                  ),
                  Text(
                    'Azimuth: ${_azimuth?.toStringAsFixed(2)}°',
                  ),
                  const SizedBox(height: 24),
                ],

                FilledButton(
                  onPressed: _calculateStarPosition,
                  child: const Text(
                    'Calculate Position',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}