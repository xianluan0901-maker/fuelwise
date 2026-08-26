import 'package:flutter/material.dart';
import '../models/payment_model.dart';

class PaymentHistoryDetailScreen extends StatelessWidget {
  final PaymentTransaction transaction;

  const PaymentHistoryDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1687E8),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              color: const Color(0xFFF0F6FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(

                    '-RM${transaction.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1687E8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.status.toUpperCase(), // "SUCCESSFUL"
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),


            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildDetailRow('Transaction Type', 'Fuel Purchase'),
                  _buildDetailRow('Transaction Details', '${transaction.fuelType} - Pump ${transaction.pumpNumber}'),
                  _buildDetailRow('Payment Method', transaction.paymentMethod),
                  _buildDetailRow('Date/Time', _formatFullDate(transaction.createdAt)), // 红框 1
                  _buildDetailRow('Card No.', 'E-Wallet'),
                  _buildDetailRow('Actual Entry', transaction.stationName), // 红框 2
                  _buildDetailRow('Actual Exit', '${transaction.stationName}\n${_formatFullDate(transaction.createdAt)}'), // 红框 3
                  _buildDetailRow('Wallet Ref', transaction.transactionId),
                  _buildDetailRow('Status', transaction.status),
                  _buildDetailRow('Transaction No.', transaction.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF153B60),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }


  String _formatFullDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}