// lib/features/reward/services/reward_service.dart

import '../../payment/models/payment_model.dart';
import '../../payment/services/payment_service.dart';

class RewardService {
  final PaymentService _paymentService = PaymentService();

  Future<Map<String, dynamic>> getUserPoints(String userId) {
    return _paymentService.getUserPoints(userId);
  }

  Future<List<Voucher>> getAvailableRewards() {
    return _paymentService.getAvailableVouchers();
  }

  Future<List<UserVoucher>> getRedemptionHistory(String userId) {
    return _paymentService.getUserVouchers(userId);
  }


  Future<List<UserVoucher>> getAvailableUserVouchers(String userId) {
    return _paymentService.getAvailableUserVouchers(userId);
  }

  Future<bool> redeemReward({
    required String userId,
    required String voucherId,
  }) {
    return _paymentService.redeemVoucher(
      userId,
      voucherId,
    );
  }
}