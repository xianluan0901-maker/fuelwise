import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment_model.dart';
import '../services/payment_service.dart';
import 'payment_history_detail_screen.dart';

// ⭐ Vehicle
import '../../vehicle/models/vehicle_model.dart';
import '../../vehicle/services/vehicle_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  final VehicleService _vehicleService = VehicleService();

  List<PaymentTransaction> _allTransactions = [];
  List<PaymentTransaction> _filteredTransactions = [];

  // Vehicle list + selected vehicle ID
  List<Vehicle> _userVehicles = [];
  String? _selectedVehicleId;

  bool _isLoading = true;
  String? _error;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();

    // ⭐ No orientation lock here.
    // The app will follow the device/emulator orientation normally.

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
      // Load transaction history + vehicle list in parallel
      final results = await Future.wait([
        _paymentService.getTransactionHistory(user.id),
        _vehicleService.getVehicles(),
      ]);

      if (!mounted) return;

      _allTransactions = results[0] as List<PaymentTransaction>;
      _userVehicles = results[1] as List<Vehicle>;

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
  // Apply Date Filter + Vehicle Filter
  // ============================================================

  void _applyFilter() {
    final filtered = _allTransactions.where((item) {
      final itemDate = item.createdAt;

      // --- Date filter ---
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

      // --- Vehicle filter ---
      if (_selectedVehicleId != null) {
        if (item.vehicleId != _selectedVehicleId) {
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
  // Reset Filters
  // ============================================================

  void _resetFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedVehicleId = null;
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

        // If end date is earlier than start date, clear it
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    // If start date is not selected, ask user to select it first
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Start Date first'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!,
      firstDate: _startDate!,
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
        automaticallyImplyLeading: false,
      ),

      body: RefreshIndicator(
        onRefresh: _loadHistory,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          child: Column(
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
                    // ------------------------------------------------
                    // Date Filter
                    // ------------------------------------------------

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

                    // ------------------------------------------------
                    // Vehicle Filter
                    // ------------------------------------------------

                    if (_userVehicles.isNotEmpty) ...[
                      _buildVehicleFilter(),
                      const SizedBox(height: 10),
                    ],

                    const Text(
                      'You can view transaction history up to 30 days',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ------------------------------------------------
                    // Apply / Clear
                    // ------------------------------------------------

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(0xFF1687E8),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                            ),

                            onPressed: _applyFilter,

                            child: const Text(
                              'APPLY FILTER',
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        if (_startDate != null ||
                            _endDate != null ||
                            _selectedVehicleId != null)
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
              // Transaction History
              // ======================================================

              _buildHistoryContent(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Vehicle Filter
  // ============================================================

  Widget _buildVehicleFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,

      children: [
        // ----------------------------------------------------------
        // All Vehicles
        // ----------------------------------------------------------

        ChoiceChip(
          label: const Text('All'),

          selected: _selectedVehicleId == null,

          onSelected: (selected) {
            setState(() {
              _selectedVehicleId = null;
            });

            _applyFilter();
          },

          selectedColor: const Color(0xFF1687E8),
          backgroundColor: const Color(0xFFF8FAFC),

          labelStyle: TextStyle(
            color: _selectedVehicleId == null
                ? Colors.white
                : const Color(0xFF153B60),

            fontWeight: _selectedVehicleId == null
                ? FontWeight.bold
                : FontWeight.normal,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),

            side: BorderSide(
              color: _selectedVehicleId == null
                  ? const Color(0xFF1687E8)
                  : const Color(0xFFDCE5ED),
            ),
          ),
        ),

        // ----------------------------------------------------------
        // Each Vehicle
        // ----------------------------------------------------------

        for (final vehicle in _userVehicles)
          ChoiceChip(
            key: ValueKey(vehicle.id),

            label: Text(vehicle.vehicleName),

            selected: _selectedVehicleId == vehicle.id,

            onSelected: (selected) {
              setState(() {
                _selectedVehicleId =
                selected ? vehicle.id : null;
              });

              _applyFilter();
            },

            selectedColor: const Color(0xFF1687E8),
            backgroundColor: const Color(0xFFF8FAFC),

            labelStyle: TextStyle(
              color: _selectedVehicleId == vehicle.id
                  ? Colors.white
                  : const Color(0xFF153B60),

              fontWeight: _selectedVehicleId == vehicle.id
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),

              side: BorderSide(
                color: _selectedVehicleId == vehicle.id
                    ? const Color(0xFF1687E8)
                    : const Color(0xFFDCE5ED),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // History Content
  // ============================================================

  Widget _buildHistoryContent() {
    // ------------------------------------------------------------
    // Loading
    // ------------------------------------------------------------

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),

        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ------------------------------------------------------------
    // Error
    // ------------------------------------------------------------

    if (_error != null) {
      return Padding(
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
      );
    }

    // ------------------------------------------------------------
    // Empty
    // ------------------------------------------------------------

    if (_filteredTransactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 80,
        ),

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

    // ------------------------------------------------------------
    // Transaction List
    // ------------------------------------------------------------

    return ListView.separated(
      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

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

          // --------------------------------------------------------
          // Station Name
          // --------------------------------------------------------

          title: Text(
            item.stationName,

            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          // --------------------------------------------------------
          // Date + Vehicle
          // --------------------------------------------------------

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                _formatDate(item.createdAt),

                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              if (item.vehicleName != null &&
                  item.vehiclePlate != null)
                Text(
                  '🚗 ${item.vehicleName} (${item.vehiclePlate})',

                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey,
                  ),
                ),
            ],
          ),

          // --------------------------------------------------------
          // Amount
          // --------------------------------------------------------

          trailing: Text(
            '-RM${item.totalAmount.toStringAsFixed(2)}',

            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          // --------------------------------------------------------
          // Open Details
          // --------------------------------------------------------

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
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

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
  // Format Date
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}