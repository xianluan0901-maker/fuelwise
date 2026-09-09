import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/vehicle_model.dart';
import '../validators/vehicle_validators.dart';

class VehicleService {
  static Future<Database>? _databaseFuture;

  final SupabaseClient _supabase = Supabase.instance.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw const VehicleValidationException(
        'Please sign in to manage your vehicles.',
      );
    }

    return user.id;
  }

  Future<Database> get _database {
    return _databaseFuture ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    try {
      final directory = await getDatabasesPath();

      return await openDatabase(
        p.join(directory, 'fuelwise_vehicles.db'),
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE vehicles (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              vehicle_name TEXT NOT NULL
                CHECK (length(trim(vehicle_name)) > 0),
              plate_number TEXT NOT NULL,
              brand TEXT,
              model TEXT,
              manufacture_year INTEGER,
              fuel_type TEXT NOT NULL
                CHECK (fuel_type IN ('RON95', 'RON97', 'Diesel')),
              fuel_efficiency REAL
                CHECK (
                  fuel_efficiency IS NULL OR
                  fuel_efficiency BETWEEN 1 AND 50
                ),
              tank_capacity REAL
                CHECK (
                  tank_capacity IS NULL OR
                  tank_capacity BETWEEN 5 AND 200
                ),
              is_default INTEGER NOT NULL DEFAULT 0
                CHECK (is_default IN (0, 1)),
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              UNIQUE(user_id, plate_number)
            )
          ''');

          await db.execute('''
            CREATE UNIQUE INDEX one_default_vehicle_per_user
            ON vehicles(user_id)
            WHERE is_default = 1
          ''');
        },
      );
    } catch (_) {
      _databaseFuture = null;
      rethrow;
    }
  }

  Vehicle _fromRow(Map<String, Object?> row) {
    return Vehicle.fromJson({
      ...row,
      'is_default': row['is_default'] == 1,
    });
  }

  Future<List<Vehicle>> getVehicles() async {
    final userId = _currentUserId;
    final db = await _database;

    final rows = await db.query(
      'vehicles',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'is_default DESC, created_at ASC, id ASC',
    );

    return rows.map(_fromRow).toList();
  }

  Future<Vehicle?> getDefaultVehicle() async {
    final userId = _currentUserId;
    final db = await _database;

    final rows = await db.query(
      'vehicles',
      where: 'user_id = ? AND is_default = 1',
      whereArgs: [userId],
      limit: 1,
    );

    return rows.isEmpty ? null : _fromRow(rows.first);
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
    final userId = _currentUserId;

    _validate(
      vehicleName: vehicleName,
      plateNumber: plateNumber,
      fuelType: fuelType,
      manufactureYear: manufactureYear,
      fuelEfficiency: fuelEfficiency,
      tankCapacity: tankCapacity,
    );

    final db = await _database;
    final normalizedPlate =
    VehicleValidators.normalizePlate(plateNumber);

    return db.transaction<Vehicle>((txn) async {
      await _checkDuplicatePlate(
        txn,
        userId: userId,
        plateNumber: normalizedPlate,
      );

      final existing = await txn.query(
        'vehicles',
        columns: ['id'],
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      final now = DateTime.now().toUtc().toIso8601String();

      final row = <String, Object?>{
        'id': const Uuid().v4(),
        'user_id': userId,
        'vehicle_name': vehicleName.trim(),
        'plate_number': normalizedPlate,
        'brand': _emptyToNull(brand),
        'model': _emptyToNull(model),
        'manufacture_year': manufactureYear,
        'fuel_type': fuelType,
        'fuel_efficiency': fuelEfficiency,
        'tank_capacity': tankCapacity,
        'is_default': existing.isEmpty ? 1 : 0,
        'created_at': now,
        'updated_at': now,
      };

      await txn.insert('vehicles', row);

      return _fromRow(row);
    });
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
    final userId = _currentUserId;

    _validate(
      vehicleName: vehicleName,
      plateNumber: plateNumber,
      fuelType: fuelType,
      manufactureYear: manufactureYear,
      fuelEfficiency: fuelEfficiency,
      tankCapacity: tankCapacity,
    );

    final db = await _database;
    final normalizedPlate =
    VehicleValidators.normalizePlate(plateNumber);

    await db.transaction((txn) async {
      await _requireVehicle(
        txn,
        userId: userId,
        vehicleId: vehicleId,
      );

      await _checkDuplicatePlate(
        txn,
        userId: userId,
        plateNumber: normalizedPlate,
        excludedVehicleId: vehicleId,
      );

      await txn.update(
        'vehicles',
        {
          'vehicle_name': vehicleName.trim(),
          'plate_number': normalizedPlate,
          'brand': _emptyToNull(brand),
          'model': _emptyToNull(model),
          'manufacture_year': manufactureYear,
          'fuel_type': fuelType,
          'fuel_efficiency': fuelEfficiency,
          'tank_capacity': tankCapacity,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [vehicleId, userId],
      );
    });
  }

  Future<void> setDefaultVehicle(String vehicleId) async {
    final userId = _currentUserId;
    final db = await _database;

    await db.transaction((txn) async {
      await _requireVehicle(
        txn,
        userId: userId,
        vehicleId: vehicleId,
      );

      final now = DateTime.now().toUtc().toIso8601String();

      await txn.update(
        'vehicles',
        {
          'is_default': 0,
          'updated_at': now,
        },
        where: 'user_id = ? AND is_default = 1',
        whereArgs: [userId],
      );

      await txn.update(
        'vehicles',
        {
          'is_default': 1,
          'updated_at': now,
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [vehicleId, userId],
      );
    });
  }

  Future<void> deleteVehicle(Vehicle vehicle) async {
    final userId = _currentUserId;
    final db = await _database;

    await db.transaction((txn) async {
      final current = await _requireVehicle(
        txn,
        userId: userId,
        vehicleId: vehicle.id,
      );

      await txn.delete(
        'vehicles',
        where: 'id = ? AND user_id = ?',
        whereArgs: [vehicle.id, userId],
      );

      if (current['is_default'] == 1) {
        final remaining = await txn.query(
          'vehicles',
          columns: ['id'],
          where: 'user_id = ?',
          whereArgs: [userId],
          orderBy: 'created_at ASC, id ASC',
          limit: 1,
        );

        if (remaining.isNotEmpty) {
          await txn.update(
            'vehicles',
            {
              'is_default': 1,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            where: 'id = ? AND user_id = ?',
            whereArgs: [remaining.first['id'], userId],
          );
        }
      }
    });
  }

  Future<Map<String, Object?>> _requireVehicle(
      DatabaseExecutor db, {
        required String userId,
        required String vehicleId,
      }) async {
    final rows = await db.query(
      'vehicles',
      where: 'id = ? AND user_id = ?',
      whereArgs: [vehicleId, userId],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const VehicleValidationException(
        'Vehicle not found. Please refresh your vehicle list.',
      );
    }

    return rows.first;
  }

  Future<void> _checkDuplicatePlate(
      DatabaseExecutor db, {
        required String userId,
        required String plateNumber,
        String? excludedVehicleId,
      }) async {
    final rows = await db.query(
      'vehicles',
      columns: ['id'],
      where: excludedVehicleId == null
          ? 'user_id = ? AND plate_number = ?'
          : 'user_id = ? AND plate_number = ? AND id != ?',
      whereArgs: [
        userId,
        plateNumber,
        if (excludedVehicleId != null) excludedVehicleId,
      ],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      throw const VehicleValidationException(
        'This plate number is already in your vehicles.',
      );
    }
  }

  void _validate({
    required String vehicleName,
    required String plateNumber,
    required String fuelType,
    int? manufactureYear,
    double? fuelEfficiency,
    double? tankCapacity,
  }) {
    VehicleValidators.validateForSave(
      name: vehicleName,
      plate: plateNumber,
      year: manufactureYear,
      efficiency: fuelEfficiency,
      capacity: tankCapacity,
    );

    if (!['RON95', 'RON97', 'Diesel'].contains(fuelType)) {
      throw const VehicleValidationException(
        'Please select a supported fuel type.',
      );
    }
  }

  String? _emptyToNull(String? value) {
    final cleaned = value?.trim();

    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  Future<String> prepareVehicleForPayment(String vehicleId) async {
    final userId = _currentUserId;
    final db = await _database;

    final row = await _requireVehicle(
      db,
      userId: userId,
      vehicleId: vehicleId,
    );

    final vehicle = _fromRow(row);
    final normalizedPlate =
    VehicleValidators.normalizePlate(vehicle.plateNumber);

    final cloudRows = await _supabase
        .from('vehicles')
        .select('id, plate_number')
        .eq('user_id', userId);

    String? serverId;

    for (final cloudRow in cloudRows) {
      if (cloudRow['id'].toString() == vehicleId) {
        serverId = vehicleId;
        break;
      }
    }

    if (serverId == null) {
      for (final cloudRow in cloudRows) {
        final cloudPlate = VehicleValidators.normalizePlate(
          cloudRow['plate_number']?.toString() ?? '',
        );

        if (cloudPlate == normalizedPlate) {
          serverId = cloudRow['id'].toString();
          break;
        }
      }
    }

    final payload = <String, dynamic>{
      'vehicle_name': vehicle.vehicleName,
      'plate_number': normalizedPlate,
      'brand': vehicle.brand,
      'model': vehicle.model,
      'manufacture_year': vehicle.manufactureYear,
      'fuel_type': vehicle.fuelType,
      'fuel_efficiency': vehicle.fuelEfficiency,
      'tank_capacity': vehicle.tankCapacity,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (serverId != null) {
      final saved = await _supabase
          .from('vehicles')
          .update(payload)
          .eq('id', serverId)
          .eq('user_id', userId)
          .select('id')
          .single();

      return saved['id'].toString();
    }

    final saved = await _supabase
        .from('vehicles')
        .insert({
      ...payload,
      'id': vehicleId,
      'user_id': userId,
      'is_default': false,
    })
        .select('id')
        .single();

    return saved['id'].toString();
  }
}