import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/payment_model.dart';
import '../../../shared/widgets/main_navigation.dart';

class ReceiptPage extends StatelessWidget {
  final PaymentTransaction transaction;

  const ReceiptPage({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Payment Receipt'),
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
        child: Column(
          children: [
            _buildSuccessHeader(),
            const SizedBox(height: 24),
            _buildTransactionDetails(),
            const SizedBox(height: 24),
            _buildQRCode(),
            const SizedBox(height: 32),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
          const SizedBox(height: 8),
          const Text(
            'Payment Successful!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF153B60),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your transaction has been completed.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFE0B2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                const SizedBox(width: 6),
                Text(
                  '+${transaction.pointsEarned} Points Earned!',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE65100),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ⭐ 只改了这个方法：加了车辆信息
  // ============================================================

  Widget _buildTransactionDetails() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF153B60),
            ),
          ),
          const Divider(color: Color(0xFFE4EBF2), height: 20),

          // ⭐ Station 信息
          _buildDetailRow('⛽ Station', transaction.stationName),

          // ⭐ 新增：车辆信息（如果有）
          if (transaction.vehicleName != null && transaction.vehiclePlate != null)
            _buildDetailRow(
              '🚗 Vehicle',
              '${transaction.vehicleName} (${transaction.vehiclePlate})',
            ),

          if (transaction.stationAddress != null)
            _buildDetailRow('📍 Address', transaction.stationAddress!),

          _buildDetailRow('🔢 Pump', '${transaction.pumpNumber}'),
          _buildDetailRow('⛽ Fuel', transaction.fuelType),
          _buildDetailRow('📊 Quantity', '${transaction.quantityLiters.toStringAsFixed(1)} L'),
          _buildDetailRow('💰 Subtotal', 'RM${transaction.subtotal.toStringAsFixed(2)}'),

          if (transaction.voucherDiscount > 0)
            _buildDetailRow('🎫 Discount', '-RM${transaction.voucherDiscount.toStringAsFixed(2)}', valueColor: Colors.green),

          _buildDetailRow(
            '💳 Total Amount',
            'RM${transaction.totalAmount.toStringAsFixed(2)}',
            isBold: true,
            valueColor: const Color(0xFF1687E8),
          ),

          _buildDetailRow('💳 Paid Via', transaction.paymentMethod),
          _buildDetailRow('⭐ Points Earned', '+${transaction.pointsEarned} pts', valueColor: Colors.orange),
          _buildDetailRow('📅 Date & Time', _formatDate(transaction.createdAt)),
          _buildDetailRow('🆔 Transaction ID', transaction.transactionId, isBold: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? const Color(0xFF153B60),
                fontSize: isBold ? 14 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    if (transaction.qrCodeData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EBF2)),
        boxShadow: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Show this QR code at the counter',
            style: TextStyle(color: Color(0xFF153B60), fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4EBF2)),
            ),
            child: QrImageView(
              data: transaction.qrCodeData!,
              size: 180,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(color: Color(0xFF1687E8), eyeShape: QrEyeShape.square),
              dataModuleStyle: const QrDataModuleStyle(color: Color(0xFF1687E8), dataModuleShape: QrDataModuleShape.square),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Transaction: ${transaction.transactionId}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ 只有 Done 按钮，没有 Share
  // ============================================================

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(
                    initialIndex: 2,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF1687E8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy, h:mm a').format(date);
  }
}