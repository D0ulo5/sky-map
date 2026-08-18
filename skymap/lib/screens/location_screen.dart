import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

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

  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  String _location = 'Location not loaded.';
  String _sensor = 'Magnetometer: waiting...';

  @override
  void initState() {
    super.initState();

    _magnetometerSubscription =
        _orientationService.magnetometer.listen((event) {
      if (!mounted) return;

      setState(() {
        _sensor =
            'Magnetometer\n'
            'X: ${event.x.toStringAsFixed(2)}\n'
            'Y: ${event.y.toStringAsFixed(2)}\n'
            'Z: ${event.z.toStringAsFixed(2)}';
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
    _magnetometerSubscription?.cancel();
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
              _sensor,
              textAlign: TextAlign.center,
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