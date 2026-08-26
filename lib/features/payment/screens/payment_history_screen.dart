import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import 'payment_history_detail_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();

  late Future<List<PaymentTransaction>> _historyFuture;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        _historyFuture = Future.error('Please login to view history');
      });
      return;
    }
    _historyFuture = _paymentService.getTransactionHistory(user.id);
  }

  void _filterHistory() {
    setState(() {});
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: const Color(0xFF1687E8),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [

          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDateDropdown(
                        hint: 'Start Date',
                        value: _startDate,
                        onChanged: (val) => setState(() => _startDate = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDateDropdown(
                        hint: 'End Date',
                        value: _endDate,
                        onChanged: (val) => setState(() => _endDate = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'You can view transaction history up to 30 days',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.grey[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _filterHistory,
                    child: const Text('SUBMIT'),
                  ),
                ),
              ],
            ),
          ),


          Expanded(
            child: FutureBuilder<List<PaymentTransaction>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No transaction history found.'));
                }

                final historyList = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  itemCount: historyList.length,
                  separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Colors.grey),
                  itemBuilder: (context, index) {
                    final item = historyList[index];

                    return ListTile(
                      contentPadding: EdgeInsets.zero,

                      title: Text(
                        item.stationName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      subtitle: Text(
                        _formatDate(item.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      trailing: Text(
                        '-RM${item.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentHistoryDetailScreen(transaction: item),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDateDropdown({
    required String hint,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value != null ? _formatDate(value) : hint,
              style: TextStyle(color: value != null ? Colors.black : Colors.grey, fontSize: 14),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}