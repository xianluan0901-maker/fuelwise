import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle_model.dart';

class VehicleService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return user.id;
  }

  Future<List<Vehicle>> getVehicles() async {
    final response = await _supabase
        .from('vehicles')
        .select()
        .eq('user_id', _currentUserId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: true);

    return (response as List)
        .map(
          (json) => Vehicle.fromJson(
        Map<String, dynamic>.from(json),
      ),
    )
        .toList();
  }

  Future<Vehicle?> getDefaultVehicle() async {
    final response = await _supabase
        .from('vehicles')
        .select()
        .eq('user_id', _currentUserId)
        .eq('is_default', true)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Vehicle.fromJson(response);
  }

  Future<Vehicle> addVehicle({
    required String vehicleName,
    required String plateNumber,
    required String fuelType,
    String? brand,
    String? model,
    int? manufactureYear,
    double? fuelEfficiency,
    double? tankCapacity,
  }) async {
    final existingVehicles = await getVehicles();

    // The first vehicle becomes the default.
    final shouldBeDefault = existingVehicles.isEmpty;

    final response = await _supabase
        .from('vehicles')
        .insert({
      'user_id': _currentUserId,
      'vehicle_name': vehicleName.trim(),
      'plate_number':
      plateNumber.trim().toUpperCase(),
      'brand': _emptyToNull(brand),
      'model': _emptyToNull(model),
      'manufacture_year': manufactureYear,
      'fuel_type': fuelType,
      'fuel_efficiency': fuelEfficiency,
      'tank_capacity': tankCapacity,
      'is_default': shouldBeDefault,
    })
        .select()
        .single();

    return Vehicle.fromJson(response);
  }

  Future<void> updateVehicle({
    required String vehicleId,
    required String vehicleName,
    required String plateNumber,
    required String fuelType,
    String? brand,
    String? model,
    int? manufactureYear,
    double? fuelEfficiency,
    double? tankCapacity,
  }) async {
    await _supabase
        .from('vehicles')
        .update({
      'vehicle_name': vehicleName.trim(),
      'plate_number':
      plateNumber.trim().toUpperCase(),
      'brand': _emptyToNull(brand),
      'model': _emptyToNull(model),
      'manufacture_year': manufactureYear,
      'fuel_type': fuelType,
      'fuel_efficiency': fuelEfficiency,
      'tank_capacity': tankCapacity,
      'updated_at':
      DateTime.now().toIso8601String(),
    })
        .eq('id', vehicleId)
        .eq('user_id', _currentUserId);
  }

  Future<void> setDefaultVehicle(
      String vehicleId,
      ) async {
    // Remove the existing default first.
    await _supabase
        .from('vehicles')
        .update({'is_default': false})
        .eq('user_id', _currentUserId)
        .eq('is_default', true);

    // Set the selected vehicle as default.
    await _supabase
        .from('vehicles')
        .update({'is_default': true})
        .eq('id', vehicleId)
        .eq('user_id', _currentUserId);
  }

  Future<void> deleteVehicle(
      Vehicle vehicle,
      ) async {
    await _supabase
        .from('vehicles')
        .delete()
        .eq('id', vehicle.id)
        .eq('user_id', _currentUserId);

    // If the deleted vehicle was the default,
    // select another existing vehicle as default.
    if (vehicle.isDefault) {
      final remainingVehicles = await getVehicles();

      if (remainingVehicles.isNotEmpty) {
        await setDefaultVehicle(
          remainingVehicles.first.id,
        );
      }
    }
  }

  String? _emptyToNull(String? value) {
    final cleanedValue = value?.trim();

    if (cleanedValue == null ||
        cleanedValue.isEmpty) {
      return null;
    }
    return cleanedValue;
  }
}