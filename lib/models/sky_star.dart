class SkyStar {
  final int id;
  final String? name;
  final String? commonName;
  final double magnitude;
  final String? spectralType;

  /// Right ascension in degrees.
  final double ra;

  /// Declination in degrees.
  final double dec;

  const SkyStar({
    required this.id,
    this.name,
    this.commonName,
    required this.magnitude,
    this.spectralType,
    required this.ra,
    required this.dec,
  });

  factory SkyStar.fromJson(
    Map<String, dynamic> json,
  ) {
    return SkyStar(
      id: json['id'] as int,
      name: json['name'] as String?,
      commonName: json['common_name'] as String?,
      magnitude: (json['magnitude'] as num).toDouble(),
      spectralType: json['spectral_type'] as String?,
      ra: (json['ra'] as num).toDouble(),
      dec: (json['dec'] as num).toDouble(),
    );
  }

  String get displayName {
    if (commonName != null &&
        commonName!.isNotEmpty) {
      return commonName!;
    }

    if (name != null && name!.isNotEmpty) {
      return name!;
    }

    return 'HR $id';
  }
}