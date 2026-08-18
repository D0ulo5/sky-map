class Star {
  const Star({
    required this.id,
    this.name,
    this.commonName,
    required this.magnitude,
    this.spectralType,
    required this.ra,
    required this.dec,
  });

  final int id;
  final String? name;
  final String? commonName;
  final double magnitude;
  final String? spectralType;

  /// Right ascension in decimal degrees.
  final double ra;

  /// Declination in decimal degrees.
  final double dec;

  factory Star.fromJson(Map<String, dynamic> json) {
    return Star(
      id: json['id'] as int,
      name: json['name'] as String?,
      commonName: json['common_name'] as String?,
      magnitude: (json['magnitude'] as num).toDouble(),
      spectralType: json['spectral_type'] as String?,
      ra: (json['ra'] as num).toDouble(),
      dec: (json['dec'] as num).toDouble(),
    );
  }
}