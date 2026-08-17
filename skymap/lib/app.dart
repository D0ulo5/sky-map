import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'services/location_service.dart';
import 'services/orientation_service.dart';

class SkyMapApp extends StatelessWidget {
  const SkyMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sky Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const LocationScreen(),
    );
  }
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final LocationService _locationService = LocationService();
  final OrientationService _orientationService = OrientationService();

  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  String _message = 'Location not loaded.';
  String _heading = 'Magnetometer: waiting...';

  Future<void> _getLocation() async {
    setState(() {
      _message = 'Getting location...';
    });

    try {
      final position = await _locationService.getCurrentLocation();

      setState(() {
        _message =
            'Latitude: ${position.latitude}\n'
            'Longitude: ${position.longitude}';
      });
    } catch (error) {
      setState(() {
        _message = error.toString();
      });
    }
  }

  void _startSensors() {
    _magnetometerSubscription ??=
        _orientationService.magnetometer.listen((event) {
      if (!mounted) {
        return;
      }

      setState(() {
        _heading =
            'Magnetometer:\n'
            'X: ${event.x.toStringAsFixed(2)}\n'
            'Y: ${event.y.toStringAsFixed(2)}\n'
            'Z: ${event.z.toStringAsFixed(2)}';
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _startSensors();
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
              _message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              _heading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _getLocation,
              child: const Text('Get Location'),
            ),
          ],
        ),
      ),
    );
  }
}