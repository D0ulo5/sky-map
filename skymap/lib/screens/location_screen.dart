import 'dart:async';

import 'package:flutter/material.dart';

import '../services/astronomy_service.dart';
import '../services/location_service.dart';
import '../services/orientation_service.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final LocationService _locationService = LocationService();
  final OrientationService _orientationService = OrientationService();
  final AstronomyService _astronomyService = AstronomyService();

  StreamSubscription<double>? _headingSubscription;

  String _location = 'Location not loaded.';
  String _sun = 'Test object not calculated.';
  double? _heading;

  @override
  void initState() {
    super.initState();

    _headingSubscription =
        _orientationService.heading.listen((heading) {
      if (!mounted) return;

      setState(() {
        _heading = heading;
      });
    });
  }

  Future<void> _loadLocation() async {
    setState(() {
      _location = 'Getting location...';
    });

    try {
      final position = await _locationService.getCurrentLocation();

      final skyPosition = _astronomyService.equatorialToHorizontal(
        rightAscension: 150.0,
        declination: 11.0,
        latitude: position.latitude,
        longitude: position.longitude,
        time: DateTime.now(),
      );

      setState(() {
        _location =
            'Latitude: ${position.latitude}\n'
            'Longitude: ${position.longitude}';

        _sun =
            'Test object: Sun\n'
            'Azimuth: ${skyPosition.azimuth.toStringAsFixed(1)}°\n'
            'Altitude: ${skyPosition.altitude.toStringAsFixed(1)}°';
      });
    } catch (error) {
      setState(() {
        _location = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _headingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sky Map'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _location,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              _sun,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              _heading == null
                  ? 'Heading: waiting...'
                  : 'Heading: ${_heading!.toStringAsFixed(1)}°',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loadLocation,
              child: const Text('Get Location'),
            ),
          ],
        ),
      ),
    );
  }
}