class FuelStation {
  final String stationId;
  final String stationName;
  final String brand;
  final String stationAddress;
  final String? stationPhone;
  final String? openingHours;
  final double latitude;
  final double longitude;

  const FuelStation({
    required this.stationId,
    required this.stationName,
    required this.brand,
    required this.stationAddress,
    required this.latitude,
    required this.longitude,
    this.stationPhone,
    this.openingHours,
  });

  factory FuelStation.fromJson(
      Map<String, dynamic> json,
      ) {
    return FuelStation(
      stationId: json['station_id']?.toString() ?? '',
      stationName: json['station_name']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      stationAddress: json['station_address']?.toString() ?? '',
      stationPhone: json['station_phone']?.toString(),
      openingHours: json['opening_hours']?.toString(),
      latitude: double.tryParse(
        json['latitude']?.toString() ?? '',
      ) ??
          0.0,
      longitude: double.tryParse(
        json['longitude']?.toString() ?? '',
      ) ??
          0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station_id': stationId,
      'station_name': stationName,
      'brand': brand,
      'station_address': stationAddress,
      'station_phone': stationPhone,
      'opening_hours': openingHours,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}