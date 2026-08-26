// features/payment/models/payment_model.dart

/// Fuel type enum with price
enum FuelType {
  ron95('RON95', 2.095),
  ron97('RON97', 2.495),
  diesel('Diesel', 1.895);

  final String label;
  final double price;

  const FuelType(this.label, this.price);

  static FuelType fromString(String value) {
    return values.firstWhere(
          (e) => e.label == value,
      orElse: () => FuelType.ron95,
    );
  }
}

/// Payment method enum
enum PaymentMethod {
  creditCard('Credit/Debit Card'),
  touchNGo('Touch n Go');

  final String label;

  const PaymentMethod(this.label);

  static PaymentMethod fromString(String value) {
    return values.firstWhere(
          (e) => e.label == value,
      orElse: () => PaymentMethod.creditCard,
    );
  }
}

/// Transaction status enum
enum TransactionStatus {
  pending('pending'),
  completed('completed'),
  failed('failed');

  final String value;

  const TransactionStatus(this.value);

  static TransactionStatus fromString(String value) {
    return values.firstWhere(
          (e) => e.value == value,
      orElse: () => TransactionStatus.pending,
    );
  }
}

/// Voucher model
class Voucher {
  final String id;
  final String name;
  final String? description;
  final int pointsRequired;
  final double discountValue;
  final String discountType; // 'fixed' or 'percentage'
  final int expiryDays;
  final bool isActive;
  final DateTime createdAt;

  const Voucher({
    required this.id,
    required this.name,
    this.description,
    required this.pointsRequired,
    required this.discountValue,
    required this.discountType,
    required this.expiryDays,
    required this.isActive,
    required this.createdAt,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'].toString(),
      name: json['name'].toString(),
      description: json['description']?.toString(),
      pointsRequired: json['points_required'] ?? 0,
      discountValue: (json['discount_value'] ?? 0).toDouble(),
      discountType: json['discount_type'].toString(),
      expiryDays: json['expiry_days'] ?? 30,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}

/// User's voucher model
class UserVoucher {
  final String id;
  final String userId;
  final String voucherId;
  final String code;
  final DateTime redeemedAt;
  final DateTime? usedAt;
  final DateTime expiryDate;
  final bool isUsed;
  final Voucher? voucher;

  const UserVoucher({
    required this.id,
    required this.userId,
    required this.voucherId,
    required this.code,
    required this.redeemedAt,
    this.usedAt,
    required this.expiryDate,
    required this.isUsed,
    this.voucher,
  });

  factory UserVoucher.fromJson(Map<String, dynamic> json) {
    return UserVoucher(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      voucherId: json['voucher_id'].toString(),
      code: json['code'].toString(),
      redeemedAt: DateTime.parse(json['redeemed_at'].toString()),
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'].toString())
          : null,
      expiryDate: DateTime.parse(json['expiry_date'].toString()),
      isUsed: json['is_used'] ?? false,
      voucher: json['vouchers'] != null
          ? Voucher.fromJson(json['vouchers'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get isAvailable => !isUsed && !isExpired;
}

/// Payment transaction model
class PaymentTransaction {
  final String id;
  final String userId;
  final String placeId;
  final String stationName;
  final String? stationAddress;
  final String? vehicleId;
  final int pumpNumber;
  final String fuelType;
  final double quantityLiters;
  final double pricePerLiter;
  final double subtotal;
  final String? voucherId;
  final double voucherDiscount;
  final double totalAmount;
  final String paymentMethod;
  final int pointsEarned;
  final String transactionId;
  final String? qrCodeData;
  final String status;
  final DateTime createdAt;

  const PaymentTransaction({
    required this.id,
    required this.userId,
    required this.placeId,
    required this.stationName,
    this.stationAddress,
    this.vehicleId,
    required this.pumpNumber,
    required this.fuelType,
    required this.quantityLiters,
    required this.pricePerLiter,
    required this.subtotal,
    this.voucherId,
    this.voucherDiscount = 0,
    required this.totalAmount,
    required this.paymentMethod,
    required this.pointsEarned,
    required this.transactionId,
    this.qrCodeData,
    required this.status,
    required this.createdAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      placeId: json['place_id'].toString(),
      stationName: json['station_name'].toString(),
      stationAddress: json['station_address']?.toString(),
      vehicleId: json['vehicle_id']?.toString(),
      pumpNumber: json['pump_number'] ?? 0,
      fuelType: json['fuel_type'].toString(),
      quantityLiters: (json['quantity_liters'] ?? 0).toDouble(),
      pricePerLiter: (json['price_per_liter'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      voucherId: json['voucher_id']?.toString(),
      voucherDiscount: (json['voucher_discount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'].toString(),
      pointsEarned: json['points_earned'] ?? 0,
      transactionId: json['transaction_id'].toString(),
      qrCodeData: json['qr_code_data']?.toString(),
      status: json['status'].toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'place_id': placeId,
      'station_name': stationName,
      'station_address': stationAddress,
      'vehicle_id': vehicleId,
      'pump_number': pumpNumber,
      'fuel_type': fuelType,
      'quantity_liters': quantityLiters,
      'price_per_liter': pricePerLiter,
      'subtotal': subtotal,
      'voucher_id': voucherId,
      'voucher_discount': voucherDiscount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'points_earned': pointsEarned,
      'transaction_id': transactionId,
      'qr_code_data': qrCodeData,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}