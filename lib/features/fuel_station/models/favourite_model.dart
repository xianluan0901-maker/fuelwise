// features/fuel_station/models/favorite_model.dart

import '../models/fuel_station_model.dart';

class Favorite {
  final String placeId;
  final String stationName;
  final String stationAddress;
  final double latitude;
  final double longitude;
  final String customName;
  final String note;
  final DateTime createdAt;

  Favorite({
    required this.placeId,
    required this.stationName,
    required this.stationAddress,
    required this.latitude,
    required this.longitude,
    this.customName = '',
    this.note = '',
    required this.createdAt,
  });


  factory Favorite.fromStation(FuelStation station) {
    return Favorite(
      placeId: station.placeId,
      stationName: station.stationName,
      stationAddress: station.stationAddress,
      latitude: station.latitude,
      longitude: station.longitude,
      createdAt: DateTime.now(),
    );
  }


  Favorite copyWith({
    String? customName,
    String? note,
  }) {
    return Favorite(
      placeId: placeId,
      stationName: stationName,
      stationAddress: stationAddress,
      latitude: latitude,
      longitude: longitude,
      customName: customName ?? this.customName,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }


  Map<String, dynamic> toJson() => {
    'place_id': placeId,
    'station_name': stationName,
    'station_address': stationAddress,
    'latitude': latitude,
    'longitude': longitude,
    'custom_name': customName,
    'note': note,
    'created_at': createdAt.toIso8601String(),
  };

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
    placeId: json['place_id'],
    stationName: json['station_name'],
    stationAddress: json['station_address'],
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    customName: json['custom_name'] ?? '',
    note: json['note'] ?? '',
    createdAt: DateTime.parse(json['created_at']),
  );
}