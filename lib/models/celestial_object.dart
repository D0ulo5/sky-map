enum CelestialObjectType {
  star,
  planet,
  sun,
  moon,
  constellation,
}

class CelestialObject {
  final String id;
  final String name;
  final CelestialObjectType type;
  final String description;

  const CelestialObject({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
  });
}