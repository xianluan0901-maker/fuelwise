import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../payment/services/payment_service.dart';
import '../../payment/models/payment_model.dart';
import 'ai_fuel_analysis_screen.dart';

class FuelReportScreen extends StatefulWidget {
  const FuelReportScreen({super.key});

  @override
  State<FuelReportScreen> createState() => _FuelReportScreenState();
}

class _FuelReportScreenState extends State<FuelReportScreen> {
  final PaymentService _paymentService = PaymentService();

  List<PaymentTransaction> _transactions = [];

  bool _isLoading = true;
  String? _error;

  // ===========================================================================
  // HARD-CODED PREVIOUS MONTH DATA
  // ===========================================================================
  //
  // These values are temporary demo data for comparison.
  // Current month data is still loaded from Supabase.
  //
  // Later, these can be replaced with real previous-month transactions.
  // ===========================================================================

  final double _previousMonthSpending = 180.00;
  final double _previousMonthLitres = 55.0;
  final int _previousMonthRefuels = 6;

  // ===========================================================================
  // Lifecycle
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  // ===========================================================================
  // Load Real Transaction Data
  // ===========================================================================

  Future<void> _loadReport() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _error = 'Please login to view your fuel report.';
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

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load fuel report: $e';
        _isLoading = false;
      });
    }
  }

  // ===========================================================================
  // Date Helpers
  // ===========================================================================

  DateTime get _now => DateTime.now();

  DateTime get _startOfCurrentMonth {
    return DateTime(
      _now.year,
      _now.month,
      1,
    );
  }

  DateTime get _startOfNextMonth {
    return DateTime(
      _now.year,
      _now.month + 1,
      1,
    );
  }

  // ===========================================================================
  // Current Month Transactions
  // ===========================================================================

  List<PaymentTransaction> get _currentMonthTransactions {
    return _transactions.where((transaction) {
      final date = transaction.createdAt;

      return !date.isBefore(_startOfCurrentMonth) &&
          date.isBefore(_startOfNextMonth);
    }).toList();
  }

  // ===========================================================================
  // Current Month Calculations - REAL DATA
  // ===========================================================================

  double get _currentMonthSpending {
    return _currentMonthTransactions.fold(
      0.0,
          (sum, transaction) => sum + transaction.totalAmount,
    );
  }

  double get _currentMonthLitres {
    return _currentMonthTransactions.fold(
      0.0,
          (sum, transaction) => sum + transaction.quantityLiters,
    );
  }

  int get _currentMonthRefuels {
    return _currentMonthTransactions.length;
  }

  double get _averageSpending {
    if (_currentMonthRefuels == 0) {
      return 0;
    }

    return _currentMonthSpending / _currentMonthRefuels;
  }

  // ===========================================================================
  // Previous Month Comparison - HARD-CODED DATA
  // ===========================================================================

  double get _spendingDifference {
    return _currentMonthSpending - _previousMonthSpending;
  }

  double get _spendingPercentageChange {
    if (_previousMonthSpending == 0) {
      return 0;
    }

    return (_spendingDifference / _previousMonthSpending) * 100;
  }

  double get _litresDifference {
    return _currentMonthLitres - _previousMonthLitres;
  }

  double get _litresPercentageChange {
    if (_previousMonthLitres == 0) {
      return 0;
    }

    return (_litresDifference / _previousMonthLitres) * 100;
  }

  int get _refuelsDifference {
    return _currentMonthRefuels - _previousMonthRefuels;
  }

  double get _refuelsPercentageChange {
    if (_previousMonthRefuels == 0) {
      return 0;
    }

    return (_refuelsDifference / _previousMonthRefuels) * 100;
  }

  double get _previousAverageSpending {
    if (_previousMonthRefuels == 0) {
      return 0;
    }

    return _previousMonthSpending / _previousMonthRefuels;
  }

  // ===========================================================================
  // Fuel Type Analysis
  // ===========================================================================

  String get _mostUsedFuelType {
    if (_currentMonthTransactions.isEmpty) {
      return 'No data';
    }

    final Map<String, int> fuelTypeCounts = {};

    for (final transaction in _currentMonthTransactions) {
      final fuelType = transaction.fuelType;

      fuelTypeCounts[fuelType] =
          (fuelTypeCounts[fuelType] ?? 0) + 1;
    }

    final sorted = fuelTypeCounts.entries.toList()
      ..sort(
            (a, b) => b.value.compareTo(a.value),
      );

    return sorted.first.key;
  }

  int get _mostUsedFuelTypeCount {
    if (_currentMonthTransactions.isEmpty) {
      return 0;
    }

    final Map<String, int> fuelTypeCounts = {};

    for (final transaction in _currentMonthTransactions) {
      fuelTypeCounts[transaction.fuelType] =
          (fuelTypeCounts[transaction.fuelType] ?? 0) + 1;
    }

    return fuelTypeCounts.values.reduce(
          (a, b) => a > b ? a : b,
    );
  }

  double get _mostUsedFuelTypePercentage {
    if (_currentMonthRefuels == 0) {
      return 0;
    }

    return (_mostUsedFuelTypeCount / _currentMonthRefuels) * 100;
  }

  // ===========================================================================
  // Station Analysis
  // ===========================================================================

  String get _mostUsedStation {
    if (_currentMonthTransactions.isEmpty) {
      return 'No data';
    }

    final Map<String, int> stationCounts = {};

    for (final transaction in _currentMonthTransactions) {
      final station = transaction.stationName;

      stationCounts[station] =
          (stationCounts[station] ?? 0) + 1;
    }

    final sorted = stationCounts.entries.toList()
      ..sort(
            (a, b) => b.value.compareTo(a.value),
      );

    return sorted.first.key;
  }

  int get _mostUsedStationCount {
    if (_currentMonthTransactions.isEmpty) {
      return 0;
    }

    final Map<String, int> stationCounts = {};

    for (final transaction in _currentMonthTransactions) {
      stationCounts[transaction.stationName] =
          (stationCounts[transaction.stationName] ?? 0) + 1;
    }

    return stationCounts.values.reduce(
          (a, b) => a > b ? a : b,
    );
  }

  // ===========================================================================
  // Petrol Brand Analysis
  // ===========================================================================
  //
  // PaymentTransaction currently does not contain a brand field.
  // Therefore, the brand is estimated from the station name.
  //
  // Later, this can be changed to retrieve the actual brand using placeId.
  // ===========================================================================

  String _detectBrandFromStationName(String stationName) {
    final name = stationName.toLowerCase();

    if (name.contains('petronas')) {
      return 'Petronas';
    }

    if (name.contains('shell')) {
      return 'Shell';
    }

    if (name.contains('petron')) {
      return 'Petron';
    }

    if (name.contains('caltex')) {
      return 'Caltex';
    }

    if (name.contains('bhp')) {
      return 'BHP';
    }

    return 'Unknown';
  }

  String get _mostUsedBrand {
    if (_currentMonthTransactions.isEmpty) {
      return 'No data';
    }

    final Map<String, int> brandCounts = {};

    for (final transaction in _currentMonthTransactions) {
      final brand = _detectBrandFromStationName(
        transaction.stationName,
      );

      if (brand != 'Unknown') {
        brandCounts[brand] =
            (brandCounts[brand] ?? 0) + 1;
      }
    }

    if (brandCounts.isEmpty) {
      return 'Not available';
    }

    final sorted = brandCounts.entries.toList()
      ..sort(
            (a, b) => b.value.compareTo(a.value),
      );

    return sorted.first.key;
  }

  int get _mostUsedBrandCount {
    if (_currentMonthTransactions.isEmpty) {
      return 0;
    }

    final Map<String, int> brandCounts = {};

    for (final transaction in _currentMonthTransactions) {
      final brand = _detectBrandFromStationName(
        transaction.stationName,
      );

      if (brand != 'Unknown') {
        brandCounts[brand] =
            (brandCounts[brand] ?? 0) + 1;
      }
    }

    if (brandCounts.isEmpty) {
      return 0;
    }

    return brandCounts.values.reduce(
          (a, b) => a > b ? a : b,
    );
  }

  double get _mostUsedBrandPercentage {
    if (_currentMonthRefuels == 0) {
      return 0;
    }

    if (_mostUsedBrand == 'Not available') {
      return 0;
    }

    return (_mostUsedBrandCount / _currentMonthRefuels) * 100;
  }

  // ===========================================================================
  // Navigation to Individual AI Analysis
  // ===========================================================================

  void _openAIAnalysis(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIFuelAnalysisScreen(
          category: category,
        ),
      ),
    );
  }

  // ===========================================================================
  // UI
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Fuel Report',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1687E8),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1687E8),
        ),
      )
          : _error != null
          ? _buildError()
          : RefreshIndicator(
        onRefresh: _loadReport,
        child: _buildReport(),
      ),
    );
  }

  // ===========================================================================
  // Error
  // ===========================================================================

  Widget _buildError() {
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
              onPressed: _loadReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Report
  // ===========================================================================

  Widget _buildReport() {
    if (_currentMonthTransactions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildEmptyReport(),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        30,
      ),
      children: [
        _buildHeader(),

        const SizedBox(height: 18),

        _buildMonthlySummary(),

        const SizedBox(height: 20),

        // ---------------------------------------------------------------------
        // Fuel Spending
        // ---------------------------------------------------------------------

        _buildReportCard(
          icon: Icons.attach_money,
          title: 'Fuel Spending',
          value:
          'RM${_currentMonthSpending.toStringAsFixed(2)}',
          subtitle: _buildSpendingSubtitle(),
          category: 'spending',
        ),

        const SizedBox(height: 14),

        // ---------------------------------------------------------------------
        // Fuel Type
        // ---------------------------------------------------------------------

        _buildReportCard(
          icon: Icons.local_fire_department,
          title: 'Fuel Type',
          value: _mostUsedFuelType,
          subtitle:
          '${_mostUsedFuelTypePercentage.toStringAsFixed(0)}% of your refuelling transactions',
          category: 'fuelType',
        ),

        const SizedBox(height: 14),

        // ---------------------------------------------------------------------
        // Most Used Station
        // ---------------------------------------------------------------------

        _buildReportCard(
          icon: Icons.local_gas_station,
          title: 'Most Used Station',
          value: _mostUsedStation,
          subtitle:
          '$_mostUsedStationCount ${_mostUsedStationCount == 1 ? 'visit' : 'visits'} this month',
          category: 'station',
        ),

        const SizedBox(height: 14),

        // ---------------------------------------------------------------------
        // Petrol Brand
        // ---------------------------------------------------------------------

        _buildReportCard(
          icon: Icons.business,
          title: 'Petrol Brand',
          value: _mostUsedBrand,
          subtitle: _mostUsedBrand == 'Not available'
              ? 'Brand information is not available'
              : '${_mostUsedBrandPercentage.toStringAsFixed(0)}% of your refuelling transactions',
          category: 'brand',
        ),

        const SizedBox(height: 20),

        _buildAdditionalStatistics(),
      ],
    );
  }

  // ===========================================================================
  // Header
  // ===========================================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Fuel Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF123A63),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_monthName(_now.month)} ${_now.year}',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Monthly Summary
  // ===========================================================================

  Widget _buildMonthlySummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1687E8),
            Color(0xFF52B6F4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Monthly Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.payments_outlined,
                  label: 'Spending',
                  value:
                  'RM${_currentMonthSpending.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.local_gas_station_outlined,
                  label: 'Refuels',
                  value: '$_currentMonthRefuels',
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.water_drop_outlined,
                  label: 'Litres',
                  value:
                  '${_currentMonthLitres.toStringAsFixed(1)} L',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Summary Item
  // ===========================================================================

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
        const SizedBox(height: 7),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Spending Subtitle
  // ===========================================================================

  String _buildSpendingSubtitle() {
    final difference = _spendingDifference.abs();
    final percentage = _spendingPercentageChange.abs();

    if (_spendingDifference < 0) {
      return '↓ RM${difference.toStringAsFixed(2)} '
          '(${percentage.toStringAsFixed(0)}%) '
          'compared with last month';
    }

    if (_spendingDifference > 0) {
      return '↑ RM${difference.toStringAsFixed(2)} '
          '(${percentage.toStringAsFixed(0)}%) '
          'compared with last month';
    }

    return 'Same spending as last month';
  }

  // ===========================================================================
  // Report Card
  // ===========================================================================

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required String category,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE4EBF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F4FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1687E8),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF123A63),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF123A63),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF718096),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openAIAnalysis(category),
              icon: const Icon(
                Icons.auto_awesome,
                size: 17,
              ),
              label: const Text(
                'Understand Why',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1687E8),
                side: const BorderSide(
                  color: Color(0xFF1687E8),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Additional Statistics
  // ===========================================================================

  Widget _buildAdditionalStatistics() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE4EBF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Statistics',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF123A63),
            ),
          ),

          const SizedBox(height: 15),

          _buildStatisticRow(
            icon: Icons.receipt_long_outlined,
            title: 'Average per refuelling',
            value:
            'RM${_averageSpending.toStringAsFixed(2)}',
          ),

          const Divider(height: 24),

          _buildStatisticRow(
            icon: Icons.water_drop_outlined,
            title: 'Total fuel purchased',
            value:
            '${_currentMonthLitres.toStringAsFixed(2)} L',
          ),

          const Divider(height: 24),

          _buildStatisticRow(
            icon: _spendingDifference > 0
                ? Icons.trending_up
                : _spendingDifference < 0
                ? Icons.trending_down
                : Icons.remove,
            title: 'Previous month spending',
            value:
            'RM${_previousMonthSpending.toStringAsFixed(2)}',
          ),

          const Divider(height: 24),

          _buildStatisticRow(
            icon: Icons.local_gas_station_outlined,
            title: 'Previous month refuels',
            value: '$_previousMonthRefuels',
          ),

          const Divider(height: 24),

          _buildStatisticRow(
            icon: Icons.water_drop_outlined,
            title: 'Previous month litres',
            value:
            '${_previousMonthLitres.toStringAsFixed(1)} L',
          ),

          const Divider(height: 24),

          _buildStatisticRow(
            icon: Icons.compare_arrows,
            title: 'Spending change',
            value:
            '${_spendingPercentageChange >= 0 ? '+' : ''}'
                '${_spendingPercentageChange.toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Statistic Row
  // ===========================================================================

  Widget _buildStatisticRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE9F4FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1687E8),
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF61758A),
            ),
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF123A63),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Empty Report
  // ===========================================================================

  Widget _buildEmptyReport() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),

          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F4FF),
              borderRadius: BorderRadius.circular(45),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              size: 45,
              color: Color(0xFF1687E8),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'No Fuel Data Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF123A63),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Your fuel report will appear here after you complete a fuel purchase.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 30),

          OutlinedButton.icon(
            onPressed: _loadReport,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }
}