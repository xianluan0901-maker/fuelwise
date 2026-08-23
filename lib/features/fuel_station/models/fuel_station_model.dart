class FuelStation {
  final String placeId;
  final String stationName;
  final String stationAddress;
  final String brand;
  final double latitude;
  final double longitude;
  final List<String> photoNames;

  const FuelStation({
    required this.placeId,
    required this.stationName,
    required this.stationAddress,
    required this.brand,
    required this.latitude,
    required this.longitude,
    this.photoNames = const [],
  });

  factory FuelStation.fromGooglePlace(Map<String, dynamic> json) {
    final displayName =
    (json['displayName']?['text'] ?? 'Unknown Station').toString();

    final address =
    (json['formattedAddress'] ?? 'Address unavailable').toString();

    final location = json['location'] as Map<String, dynamic>?;

    final photos = (json['photos'] as List<dynamic>?)
        ?.map((photo) => photo['name'].toString())
        .toList() ??
        [];

    return FuelStation(
      placeId: json['id'].toString(),
      stationName: displayName,
      stationAddress: address,
      brand: _detectBrand(displayName),
      latitude: (location?['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (location?['longitude'] as num?)?.toDouble() ?? 0.0,
      photoNames: photos,
    );
  }

  static String _detectBrand(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('petronas')) return 'Petronas';
    if (lower.contains('shell')) return 'Shell';
    if (lower.contains('petron')) return 'Petron';
    if (lower.contains('caltex')) return 'Caltex';
    if (lower.contains('bhp')) return 'BHP';

    return 'Other';
  }
}