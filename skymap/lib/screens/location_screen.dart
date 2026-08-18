import 'dart:async';

import 'package:flutter/material.dart';

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

  StreamSubscription<double>? _headingSubscription;

  String _location = 'Location not loaded.';
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

      setState(() {
        _location =
            'Latitude: ${position.latitude}\n'
            'Longitude: ${position.longitude}';
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