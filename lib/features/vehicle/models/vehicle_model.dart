class Vehicle {
  final String id;
  final String userId;
  final String vehicleName;
  final String plateNumber;
  final String? brand;
  final String? model;
  final int? manufactureYear;
  final String fuelType;
  final double? fuelEfficiency;
  final double? tankCapacity;
  final bool isDefault;
  final DateTime? createdAt;

  const Vehicle({
    required this.id,
    required this.userId,
    required this.vehicleName,
    required this.plateNumber,
    required this.fuelType,
    required this.isDefault,
    this.brand,
    this.model,
    this.manufactureYear,
    this.fuelEfficiency,
    this.tankCapacity,
    this.createdAt,
  });

  factory Vehicle.fromJson(
      Map<String, dynamic> json,
      ) {
    return Vehicle(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      vehicleName:
      json['vehicle_name']?.toString() ?? '',
      plateNumber:
      json['plate_number']?.toString() ?? '',
      brand: json['brand']?.toString(),
      model: json['model']?.toString(),
      manufactureYear: int.tryParse(
        json['manufacture_year']?.toString() ?? '',
      ),
      fuelType:
      json['fuel_type']?.toString() ?? 'RON95',
      fuelEfficiency: double.tryParse(
        json['fuel_efficiency']?.toString() ?? '',
      ),
      tankCapacity: double.tryParse(
        json['tank_capacity']?.toString() ?? '',
      ),
      isDefault: json['is_default'] == true,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(
        json['created_at'].toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'vehicle_name': vehicleName,
      'plate_number': plateNumber,
      'brand': brand,
      'model': model,
      'manufacture_year': manufactureYear,
      'fuel_type': fuelType,
      'fuel_efficiency': fuelEfficiency,
      'tank_capacity': tankCapacity,
      'is_default': isDefault,
    };
  }
}