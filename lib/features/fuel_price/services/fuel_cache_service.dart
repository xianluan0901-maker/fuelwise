import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/fuel_price_model.dart';

class FuelCacheService {
  static const String _latestPriceKey = 'latest_fuel_price';

  Future<void> saveLatestPrice(FuelPrice price) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_latestPriceKey, jsonEncode(price.toJson()));
  }

  Future<FuelPrice?> getCachedLatestPrice() async {
    final preferences = await SharedPreferences.getInstance();
    final savedPrice = preferences.getString(_latestPriceKey);

    if (savedPrice == null) {
      return null;
    }

    try {
      final decodedPrice = jsonDecode(savedPrice);

      if (decodedPrice is Map<String, dynamic>) {
        return FuelPrice.fromJson(decodedPrice);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasFuelPriceChanged(FuelPrice latestPrice) async {
    final previousPrice = await getCachedLatestPrice();

    if (previousPrice == null) {
      return false;
    }

    return previousPrice.ron95 != latestPrice.ron95 ||
        previousPrice.ron97 != latestPrice.ron97 ||
        previousPrice.diesel != latestPrice.diesel ||
        previousPrice.dieselEastMalaysia != latestPrice.dieselEastMalaysia ||
        previousPrice.ron95Budi != latestPrice.ron95Budi;
  }
}
