import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class VehicleValidators {
  static const int maxNameLength = 40;

  static String normalizePlate(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }

  static String? vehicleName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Please enter a vehicle name.';
    }

    if (name.characters.length > maxNameLength) {
      return 'Use no more than 40 characters.';
    }

    return null;
  }

  static String? plateNumber(String? value) {
    final plate = normalizePlate(value ?? '');

    if (plate.isEmpty) {
      return 'Please enter a plate number.';
    }

    // Common state/territory series, including trailing-letter formats.
    // This checks structure, not whether a particular series was issued.
    final ordinary = RegExp(
      r'^[ABCD F J K L M N P Q R S T V W]'
      r'[A-HJ-NP-Y]{0,2}[1-9][0-9]{0,3}[A-HJ-NP-Y]?$'
          .replaceAll(' ', ''),
    );

    // Explicitly supported special series. Extend this list as needed.
    final special = RegExp(
      r'^(?:PUTRAJAYA|MALAYSIA|PATRIOT|SUKOM|BAMBEE|'
      r'RIMAU|PERFECT|VIP|NAAM|GT|G|X|XO|XX|XXX|'
      r'Y|YY|YYY|SMS|KU|UM|UKM|UPM|UTM|USM|UUM|'
      r'UNIMAS|UMS|UITM|IIUM|UTEM|UTHM|UMP|UNIMAP)'
      r'[1-9][0-9]{0,3}$',
    );

    if (!ordinary.hasMatch(plate) && !special.hasMatch(plate)) {
      return 'Enter a supported Malaysian plate, e.g. ABC1234 '
          'or SAB1234A.';
    }

    return null;
  }

  static const int maxBrandLength = 30;
  static const int maxModelLength = 50;

  static String? vehicleBrand(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return null;

    if (text.characters.length > maxBrandLength) {
      return 'Use no more than $maxBrandLength characters.';
    }

    return null;
  }

  static String? vehicleModel(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return null;

    if (text.characters.length > maxModelLength) {
      return 'Use no more than $maxModelLength characters.';
    }

    return null;
  }

  static String? manufactureYear(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return null;

    final currentYear = DateTime.now().year;
    final year = int.tryParse(text);

    if (!RegExp(r'^[0-9]{4}$').hasMatch(text) ||
        year == null ||
        year < 1950 ||
        year > currentYear) {
      return 'Enter a year from 1950 to $currentYear.';
    }

    return null;
  }

  static String? fuelEfficiency(String? value) {
    return _decimalRange(
      value,
      minimum: 1,
      maximum: 50,
      unit: 'km/L',
    );
  }

  static String? tankCapacity(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Please enter the tank capacity.';
    }

    return _decimalRange(
      text,
      minimum: 5,
      maximum: 200,
      unit: 'L',
    );
  }

  static String? _decimalRange(
      String? value, {
        required double minimum,
        required double maximum,
        required String unit,
      }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return null;

    if (!RegExp(r'^[0-9]+(?:\.[0-9]{1,2})?$').hasMatch(text)) {
      return 'Enter a number with up to 2 decimal places.';
    }

    final number = double.tryParse(text);

    if (number == null ||
        !number.isFinite ||
        number < minimum ||
        number > maximum) {
      return 'Enter ${minimum.toInt()}–${maximum.toInt()} $unit.';
    }

    return null;
  }

  static List<String> unusualValues({
    double? fuelEfficiency,
    double? tankCapacity,
  }) {
    return [
      if (fuelEfficiency != null &&
          (fuelEfficiency < 5 || fuelEfficiency > 30))
        'Fuel efficiency: $fuelEfficiency km/L',
      if (tankCapacity != null &&
          (tankCapacity < 20 || tankCapacity > 100))
        'Tank capacity: $tankCapacity L',
    ];
  }

  // Used by the service so callers cannot bypass the form validators.
  static void validateForSave({
    required String name,
    required String plate,
    int? year,
    double? efficiency,
    double? capacity,
  }) {
    final errors = [
      vehicleName(name),
      plateNumber(plate),
      manufactureYear(year?.toString()),
      fuelEfficiency(efficiency?.toString()),
      tankCapacity(capacity?.toString()),
    ];

    for (final error in errors) {
      if (error != null) {
        throw VehicleValidationException(error);
      }
    }
  }
}

class VehicleValidationException implements Exception {
  final String message;

  const VehicleValidationException(this.message);

  @override
  String toString() => message;
}

// Rejects an invalid edit instead of silently removing part of a number.
class VehicleDecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (!newValue.composing.isCollapsed) return newValue;

    return RegExp(r'^[0-9]{0,3}(?:\.[0-9]{0,2})?$')
        .hasMatch(newValue.text)
        ? newValue
        : oldValue;
  }
}