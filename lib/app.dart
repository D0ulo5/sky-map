import 'package:flutter/material.dart';

import 'screens/location_screen.dart';

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