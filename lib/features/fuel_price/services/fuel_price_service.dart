import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/fuel_price_model.dart';

class FuelPriceService {
  static const String _apiUrl =
      'https://api.data.gov.my/data-catalogue'
      '?id=fuelprice&limit=500';

  Future<List<FuelPrice>> getFuelPriceHistory() async {
    final response = await http
        .get(Uri.parse(_apiUrl), headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Unable to retrieve fuel prices. '
        'Server returned ${response.statusCode}.',
      );
    }

    final dynamic decodedData = jsonDecode(response.body);

    if (decodedData is! List) {
      throw Exception('Unexpected response from the fuel-price API.');
    }

    final prices = decodedData
        .whereType<Map<String, dynamic>>()
        .where(
          (record) =>
              record['series_type'] == null || record['series_type'] == 'level',
        )
        .map(FuelPrice.fromJson)
        .where((price) => price.ron95 > 0)
        .toList();

    prices.sort((first, second) => second.date.compareTo(first.date));

    if (prices.isEmpty) {
      throw Exception('No fuel-price records were returned.');
    }

    return prices;
  }

  Future<FuelPrice> getLatestFuelPrice() async {
    final history = await getFuelPriceHistory();
    return history.first;
  }
}
