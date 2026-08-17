import 'package:flutter/material.dart';

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
      home: const Scaffold(
        body: Center(
          child: Text('Sky Map'),
        ),
      ),
    );
  }
}