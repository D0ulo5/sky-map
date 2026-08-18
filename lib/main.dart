import 'package:flutter/material.dart';

import 'screens/sky_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      home: SkyScreen(),
    ),
  );
}