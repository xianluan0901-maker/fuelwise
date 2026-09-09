// features/payment/services/payment_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/payment_model.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // ============================================================
  // Points Configuration
  // ============================================================

  /// Get points configuration from database
  Future<Map<String, dynamic>> getPointsConfig() async {
    final response = await _supabase
        .from('points_config')
        .select()
        .maybeSingle();

    if (response == null) {
      return {
        'points_per_rm': 10,
        'minimum_amount': 5.00,
        'max_points_per_trans': 50,
      };
    }

    return {
      'points_per_rm': response['points_per_rm'] ?? 10,
      'minimum_amount': (response['minimum_amount'] ?? 5.00).toDouble(),
      'max_points_per_trans': response['max_points_per_trans'] ?? 50,
    };
  }

  /// Calculate points based on amount
  Future<int> calculatePoints(double amount) async {
    final config = await getPointsConfig();

    final pointsPerRm = config['points_per_rm'] as int;
    final minimumAmount = config['minimum_amount'] as double;
    final maxPoints = config['max_points_per_trans'] as int;

    // Check minimum amount
    if (amount < minimumAmount) return 0;

    // Calculate points
    int points = (amount / pointsPerRm).floor();

    // Check max limit
    if (points > maxPoints) return maxPoints;

    return points;
  }

  // ============================================================
  // User Points
  // ============================================================

  /// Get user's points information
  Future<Map<String, dynamic>> getUserPoints(String userId) async {
    final response = await _supabase
        .from('user_points')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return {
        'total_points': 0,
        'points_spent': 0,
        'available_points': 0,
      };
    }

    return {
      'total_points': response['total_points'] ?? 0,
      'points_spent': response['points_spent'] ?? 0,
      'available_points': response['available_points'] ?? 0,
    };
  }

  /// Update user's points
  Future<void> updateUserPoints(String userId, int points) async {
    final existing = await _supabase
        .from('user_points')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      final currentTotal = existing['total_points'] ?? 0;
      final currentAvailable = existing['available_points'] ?? 0;

      await _supabase.from('user_points').update({
        'total_points': currentTotal + points,
        'available_points': currentAvailable + points,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    } else {
      await _supabase.from('user_points').insert({
        'user_id': userId,
        'total_points': points,
        'points_spent': 0,
        'available_points': points,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ============================================================
  // Vouchers
  // ============================================================

  /// Get all available vouchers
  Future<List<Voucher>> getAvailableVouchers() async {
    final response = await _supabase
        .from('vouchers')
        .select()
        .eq('is_active', true)
        .order('points_required', ascending: true);

    return response.map((json) => Voucher.fromJson(json)).toList();
  }

  /// Get user's redeemed vouchers
  Future<List<UserVoucher>> getUserVouchers(String userId) async {
    final response = await _supabase
        .from('user_vouchers')
        .select('*, vouchers(*)')
        .eq('user_id', userId)
        .order('redeemed_at', ascending: false);

    return response.map((json) => UserVoucher.fromJson(json)).toList();
  }

  /// Get user's available vouchers (unused and not expired)
  Future<List<UserVoucher>> getAvailableUserVouchers(String userId) async {
    final allVouchers = await getUserVouchers(userId);
    return allVouchers.where((v) => v.isAvailable).toList();
  }

  /// Redeem a voucher using points
  Future<bool> redeemVoucher(String userId, String voucherId) async {
    try {
      // Get voucher details
      final voucherData = await _supabase
          .from('vouchers')
          .select()
          .eq('id', voucherId)
          .maybeSingle();

      if (voucherData == null) return false;

      final voucher = Voucher.fromJson(voucherData);

      // Check user's available points
      final userPoints = await getUserPoints(userId);
      if (userPoints['available_points'] < voucher.pointsRequired) {
        return false; // Not enough points
      }

      // Generate unique voucher code
      final code = _generateVoucherCode();

      // Create user voucher
      await _supabase.from('user_vouchers').insert({
        'user_id': userId,
        'voucher_id': voucherId,
        'code': code,
        'redeemed_at': DateTime.now().toIso8601String(),
        'expiry_date': DateTime.now()
            .add(Duration(days: voucher.expiryDays))
            .toIso8601String(),
        'is_used': false,
      });

      // Deduct points
      await _supabase.from('user_points').update({
        'points_spent': userPoints['points_spent'] + voucher.pointsRequired,
        'available_points': userPoints['available_points'] - voucher.pointsRequired,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error redeeming voucher: $e');
      return false;
    }
  }

  /// Generate unique voucher code
  String _generateVoucherCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = 'VOUCHER-';
    for (int i = 0; i < 8; i++) {
      final random = DateTime.now().millisecondsSinceEpoch % chars.length;
      code += chars[random.toInt()];
    }
    return code;
  }

  // ============================================================
  // Payment Processing
  // ============================================================

  /// Process payment and save transaction
  Future<PaymentTransaction> processPayment({
    required String userId,
    required String placeId,
    required String stationName,
    String? stationAddress,
    String? vehicleId,
    String? vehicleName,      // ⭐ 新增
    String? vehiclePlate,     // ⭐ 新增
    required int pumpNumber,
    required String fuelType,
    required double quantityLiters,
    required double pricePerLiter,
    String? voucherId,
    required String paymentMethod,
  }) async {
    // 1. Calculate subtotal
    final subtotal = quantityLiters * pricePerLiter;

    // 2. Calculate discount
    double voucherDiscount = 0;
    String? appliedVoucherId;

    if (voucherId != null) {
      final voucherData = await _supabase
          .from('vouchers')
          .select()
          .eq('id', voucherId)
          .maybeSingle();

      if (voucherData != null) {
        final voucher = Voucher.fromJson(voucherData);
        appliedVoucherId = voucher.id;

        if (voucher.discountType == 'fixed') {
          voucherDiscount = voucher.discountValue;
        } else {
          // percentage
          voucherDiscount = subtotal * (voucher.discountValue / 100);
        }

        // Discount cannot exceed subtotal
        if (voucherDiscount > subtotal) {
          voucherDiscount = subtotal;
        }
      }
    }

    // 3. Calculate total amount
    final totalAmount = subtotal - voucherDiscount;

    // 4. Calculate points earned
    final pointsEarned = await calculatePoints(totalAmount);

    // 5. Generate transaction ID
    final transactionId = _generateTransactionId();

    // 6. Generate QR code data
    final qrData = _generateQRData(transactionId);

    // 7. Create transaction object
    final transaction = PaymentTransaction(
      id: _uuid.v4(),
      userId: userId,
      placeId: placeId,
      stationName: stationName,
      stationAddress: stationAddress,
      vehicleId: vehicleId,
      vehicleName: vehicleName,      // ⭐ 新增
      vehiclePlate: vehiclePlate,    // ⭐ 新增
      pumpNumber: pumpNumber,
      fuelType: fuelType,
      quantityLiters: quantityLiters,
      pricePerLiter: pricePerLiter,
      subtotal: subtotal,
      voucherId: appliedVoucherId,
      voucherDiscount: voucherDiscount,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      pointsEarned: pointsEarned,
      transactionId: transactionId,
      qrCodeData: qrData,
      status: 'completed',
      createdAt: DateTime.now(),
    );

    // 8. Save transaction to database
    await _saveTransaction(transaction);

    // 9. Update user points
    if (pointsEarned > 0) {
      await updateUserPoints(userId, pointsEarned);
    }

    // 10. Mark voucher as used
    if (appliedVoucherId != null) {
      await _markVoucherAsUsed(userId, appliedVoucherId);
    }

    return transaction;
  }

  /// Save transaction to database
  Future<void> _saveTransaction(PaymentTransaction transaction) async {
    await _supabase.from('payment_transactions').insert(transaction.toJson());
  }

  /// Mark voucher as used
  Future<void> _markVoucherAsUsed(String userId, String voucherId) async {
    await _supabase
        .from('user_vouchers')
        .update({
      'is_used': true,
      'used_at': DateTime.now().toIso8601String(),
    })
        .eq('user_id', userId)
        .eq('voucher_id', voucherId)
        .eq('is_used', false);
  }

  /// Generate transaction ID
  String _generateTransactionId() {
    final now = DateTime.now();
    return 'TX${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch.toString().substring(8, 13)}';
  }

  /// Generate QR code data
  String _generateQRData(String transactionId) {
    return 'PAYMENT:$transactionId:${DateTime.now().millisecondsSinceEpoch}';
  }

  // ============================================================
  // Transaction History
  // ============================================================

  /// Get user's transaction history
  Future<List<PaymentTransaction>> getTransactionHistory(String userId) async {
    final response = await _supabase
        .from('payment_transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response.map((json) => PaymentTransaction.fromJson(json)).toList();
  }

  /// Get transaction by ID
  Future<PaymentTransaction?> getTransactionById(String transactionId) async {
    final response = await _supabase
        .from('payment_transactions')
        .select()
        .eq('transaction_id', transactionId)
        .maybeSingle();

    if (response == null) return null;
    return PaymentTransaction.fromJson(response);
  }
}