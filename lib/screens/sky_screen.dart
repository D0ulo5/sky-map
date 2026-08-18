import 'dart:async';

import 'package:flutter/material.dart';

import '../models/device_orientation.dart';
import '../services/orientation_service.dart';
import '../widgets/horizon_painter.dart';

class SkyScreen extends StatefulWidget {
  const SkyScreen({super.key});

  @override
  State<SkyScreen> createState() => _SkyScreenState();
}

class _SkyScreenState extends State<SkyScreen> {
  final OrientationService _orientationService =
      OrientationService();

  StreamSubscription<DeviceOrientation>? _subscription;

  DeviceOrientation? _orientation;

  @override
  void initState() {
    super.initState();

    _subscription = _orientationService.orientationStream.listen(
      (orientation) {
        if (!mounted) {
          return;
        }

        setState(() {
          _orientation = orientation;
        });
      },
    );

    _orientationService.start();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _orientationService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = _orientation;

    return Scaffold(
      backgroundColor: Colors.black,
      body: orientation == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : CustomPaint(
              painter: HorizonPainter(
                orientation: orientation,
              ),
              child: const SizedBox.expand(),
            ),
    );
  }
}