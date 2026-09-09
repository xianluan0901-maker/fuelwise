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

  List<PaymentTransaction> _allTransactions = [];
  List<PaymentTransaction> _filteredTransactions = [];

  bool _isLoading = true;
  String? _error;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // ============================================================
  // Load Transaction History
  // ============================================================

  Future<void> _loadHistory() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _error = 'Please login to view history';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transactions =
      await _paymentService.getTransactionHistory(user.id);

      if (!mounted) return;

      _allTransactions = transactions;
      _applyFilter();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Error loading history: $e';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // Apply Date Filter
  // ============================================================

  void _applyFilter() {
    final filtered = _allTransactions.where((item) {
      final itemDate = item.createdAt;

      // Start date
      if (_startDate != null) {
        final startOfDay = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
        );

        if (itemDate.isBefore(startOfDay)) {
          return false;
        }
      }

      // End date
      if (_endDate != null) {
        final endOfDay = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          23,
          59,
          59,
          999,
        );

        if (itemDate.isAfter(endOfDay)) {
          return false;
        }
      }

      return true;
    }).toList();

    setState(() {
      _filteredTransactions = filtered;
      _isLoading = false;
    });
  }

  // ============================================================
  // Reset Date Filter
  // ============================================================

  void _resetFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });

    _applyFilter();
  }

  // ============================================================
  // Date Picker
  // ============================================================

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  // ============================================================
  // UI
  // ============================================================

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
          // ======================================================
          // Filter Section
          // ======================================================

          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDateDropdown(
                        hint: 'Start Date',
                        value: _startDate,
                        onTap: _selectStartDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDateDropdown(
                        hint: 'End Date',
                        value: _endDate,
                        onTap: _selectEndDate,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                const Text(
                  'You can view transaction history up to 30 days',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1687E8),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _applyFilter,
                        child: const Text('APPLY FILTER'),
                      ),
                    ),

                    const SizedBox(width: 10),

                    if (_startDate != null || _endDate != null)
                      TextButton(
                        onPressed: _resetFilter,
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ======================================================
          // Transaction History List
          // ======================================================

          Expanded(
            child: _buildHistoryContent(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // History Content
  // ============================================================

  Widget _buildHistoryContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadHistory,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredTransactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No transaction history found.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          20,
        ),
        itemCount: _filteredTransactions.length,
        separatorBuilder: (context, index) {
          return const Divider(
            height: 1,
            color: Colors.grey,
          );
        },
        itemBuilder: (context, index) {
          final item = _filteredTransactions[index];

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
                  builder: (context) =>
                      PaymentHistoryDetailScreen(
                        transaction: item,
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // Date Dropdown
  // ============================================================

  Widget _buildDateDropdown({
    required String hint,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value != null
                    ? _formatDate(value)
                    : hint,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value != null
                      ? Colors.black
                      : Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),

            const Icon(
              Icons.arrow_drop_down,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Helpers
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}