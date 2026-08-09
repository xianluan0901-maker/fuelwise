class FuelPrice {
  final DateTime date;
  final double ron95;
  final double ron97;
  final double diesel;
  final double dieselEastMalaysia;
  final double? ron95Budi;
  final double? ron95Skps;

  const FuelPrice({
    required this.date,
    required this.ron95,
    required this.ron97,
    required this.diesel,
    required this.dieselEastMalaysia,
    this.ron95Budi,
    this.ron95Skps,
  });

  factory FuelPrice.fromJson(Map<String, dynamic> json) {
    return FuelPrice(
      date: DateTime.parse(json['date'].toString()),
      ron95: _toDouble(json['ron95']),
      ron97: _toDouble(json['ron97']),
      diesel: _toDouble(json['diesel']),
      dieselEastMalaysia: _toDouble(json['diesel_eastmsia']),
      ron95Budi: _toNullableDouble(json['ron95_budi95']),
      ron95Skps: _toNullableDouble(json['ron95_skps']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'ron95': ron95,
      'ron97': ron97,
      'diesel': diesel,
      'diesel_eastmsia': dieselEastMalaysia,
      'ron95_budi95': ron95Budi,
      'ron95_skps': ron95Skps,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }

    return double.tryParse(value.toString());
  }

  double dieselForRegion(bool isEastMalaysia) {
    return isEastMalaysia ? dieselEastMalaysia : diesel;
  }
}
