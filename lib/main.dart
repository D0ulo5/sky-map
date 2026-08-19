import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/sky_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      home: SkyScreen(),
    ),
  );
}