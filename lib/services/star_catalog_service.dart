import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/star.dart';

class StarCatalogService {
  static const String _assetPath = 'assets/data/stars.json';

  Future<List<Star>> loadStars() async {
    final jsonString = await rootBundle.loadString(_assetPath);

    final json = jsonDecode(jsonString) as List<dynamic>;

    return json
        .map(
          (item) => Star.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}