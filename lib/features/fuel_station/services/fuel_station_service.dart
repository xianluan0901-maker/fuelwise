import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:fuelwisee/features/fuel_station/models/fuel_station_model.dart';

class FuelStationService {
  static const String apiKey =
      'AIzaSyDSQNknVhOAC8Sd_Dd5pv4X2UA_K8E_-J0';

  static const String _placesBase =
      'https://places.googleapis.com/v1';

  // ============================================================
  // Nearby Search
  // Find real fuel stations within 10 km
  // ============================================================

  Future<List<FuelStation>> getNearbyStations({
    required double latitude,
    required double longitude,
    double radius = 10000,
  }) async {
    final url = Uri.parse(
      '$_placesBase/places:searchNearby',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': [
          'places.id',
          'places.displayName',
          'places.formattedAddress',
          'places.location',
          'places.photos',
        ].join(','),
      },
      body: jsonEncode({
        'includedTypes': ['gas_station'],
        'maxResultCount': 20,
        'locationRestriction': {
          'circle': {
            'center': {
              'latitude': latitude,
              'longitude': longitude,
            },
            'radius': radius,
          },
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Nearby Search failed: '
            '${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    final places =
        data['places'] as List<dynamic>? ?? [];

    return places
        .map(
          (place) => FuelStation.fromGooglePlace(
        place as Map<String, dynamic>,
      ),
    )
        .where(
          (station) =>
      station.latitude != 0.0 &&
          station.longitude != 0.0,
    )
        .toList();
  }

  // ============================================================
  // Text Search
  // Search by station name / address
  // ============================================================

  Future<List<FuelStation>> searchStations({
    required String query,
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(
      '$_placesBase/places:searchText',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': [
          'places.id',
          'places.displayName',
          'places.formattedAddress',
          'places.location',
          'places.photos',
        ].join(','),
      },
      body: jsonEncode({
        'textQuery': query,
        'includedType': 'gas_station',
        'strictTypeFiltering': true,
        'pageSize': 20,
        'locationBias': {
          'circle': {
            'center': {
              'latitude': latitude,
              'longitude': longitude,
            },
            'radius': 10000,
          },
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Text Search failed: '
            '${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    final places =
        data['places'] as List<dynamic>? ?? [];

    return places
        .map(
          (place) => FuelStation.fromGooglePlace(
        place as Map<String, dynamic>,
      ),
    )
        .where(
          (station) =>
      station.latitude != 0.0 &&
          station.longitude != 0.0,
    )
        .toList();
  }

  // ============================================================
  // Place Details
  // ============================================================

  Future<Map<String, dynamic>> getStationDetails(
      String placeId,
      ) async {
    final url = Uri.parse(
      '$_placesBase/places/$placeId',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,

        // Request the information needed by
        // StationDetailScreen.
        'X-Goog-FieldMask': [
          'id',
          'displayName',
          'formattedAddress',
          'location',
          'regularOpeningHours',
          'photos',
          'nationalPhoneNumber',
          'internationalPhoneNumber',
        ].join(','),
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Place Details failed: '
            '${response.statusCode} ${response.body}',
      );
    }

    return jsonDecode(response.body)
    as Map<String, dynamic>;
  }

  // ============================================================
  // Google Photo URL
  // ============================================================

  String getPhotoUrl(String photoName) {
    return 'https://places.googleapis.com/v1/$photoName/media'
        '?maxWidthPx=800'
        '&key=$apiKey';
  }
}