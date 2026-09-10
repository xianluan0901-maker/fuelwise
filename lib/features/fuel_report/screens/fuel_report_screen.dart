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

  // ===========================================================================
  // SELECTED MONTH
  // ===========================================================================

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  // ===========================================================================
  // TRANSACTIONS
  // ===========================================================================

  List<PaymentTransaction> _transactions = [];

  bool _isLoading = true;
  String? _error;

  // ===========================================================================
  // DUMMY HISTORICAL DATA
  // ===========================================================================
  //
  // July and August use dummy data.
  // September/current month uses real Supabase transaction data.
  //
  // ===========================================================================

  final Map<String, Map<String, dynamic>> _dummyMonthlyData = {
    'July 2026': {
      'spending': 165.50,
      'litres': 51.5,
      'refuels': 5,
      'brand': 'Shell',
      'brandPercentage': 60.0,
    },
    'August 2026': {
      'spending': 180.00,
      'litres': 55.0,
      'refuels': 6,
      'brand': 'Petronas',
      'brandPercentage': 66.7,
    },
  };

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  // ===========================================================================
  // LOAD REAL TRANSACTION DATA
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
  // DATE HELPERS
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

  String get _selectedMonthName {
    return _monthName(_selectedMonth);
  }

  bool get _isSelectedCurrentMonth {
    return _selectedYear == _now.year &&
        _selectedMonth == _now.month;
  }

  // ===========================================================================
  // MONTH NAVIGATION
  // ===========================================================================

  void _goToPreviousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
  }

  void _goToNextMonth() {
    final now = DateTime.now();

    // Do not allow future months.
    if (_selectedYear == now.year &&
        _selectedMonth == now.month) {
      return;
    }

    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
  }

  // ===========================================================================
  // CURRENT MONTH TRANSACTIONS - REAL DATA
  // ===========================================================================

  List<PaymentTransaction> get _currentMonthTransactions {
    return _transactions.where((transaction) {
      final date = transaction.createdAt;

      return !date.isBefore(_startOfCurrentMonth) &&
          date.isBefore(_startOfNextMonth);
    }).toList();
  }

  // ===========================================================================
  // CURRENT MONTH CALCULATIONS - REAL DATA
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

  // ===========================================================================
  // SELECTED MONTH DUMMY DATA
  // ===========================================================================

  Map<String, dynamic>? get _selectedDummyData {
    final key = '$_selectedMonthName $_selectedYear';

    return _dummyMonthlyData[key];
  }

  // ===========================================================================
  // SELECTED MONTH SPENDING
  // ===========================================================================

  double get _selectedSpending {
    // Current month = real Supabase data
    if (_isSelectedCurrentMonth) {
      return _currentMonthSpending;
    }

    // Historical months = dummy data
    return _selectedDummyData?['spending'] ?? 0.0;
  }

  // ===========================================================================
  // SELECTED MONTH LITRES
  // ===========================================================================

  double get _selectedLitres {
    // Current month = real Supabase data
    if (_isSelectedCurrentMonth) {
      return _currentMonthLitres;
    }

    // Historical months = dummy data
    return _selectedDummyData?['litres'] ?? 0.0;
  }

  // ===========================================================================
  // SELECTED MONTH REFUELS
  // ===========================================================================

  int get _selectedRefuels {
    // Current month = real Supabase data
    if (_isSelectedCurrentMonth) {
      return _currentMonthRefuels;
    }

    // Historical months = dummy data
    return _selectedDummyData?['refuels'] ?? 0;
  }

  // ===========================================================================
  // SELECTED MONTH AVERAGE
  // ===========================================================================

  double get _selectedAverageSpending {
    if (_selectedRefuels == 0) {
      return 0;
    }

    return _selectedSpending / _selectedRefuels;
  }

  // ===========================================================================
  // SELECTED MONTH PETROL BRAND
  // ===========================================================================

  String get _selectedBrand {
    // Current month = calculate from real transactions
    if (_isSelectedCurrentMonth) {
      return _mostUsedBrand;
    }

    // Historical months = dummy brand
    return _selectedDummyData?['brand'] ?? 'Not available';
  }

  // ===========================================================================
  // SELECTED MONTH PETROL BRAND PERCENTAGE
  // ===========================================================================

  double get _selectedBrandPercentage {
    // Current month = calculate from real transactions
    if (_isSelectedCurrentMonth) {
      return _mostUsedBrandPercentage;
    }

    // Historical months = dummy percentage
    final percentage =
    _selectedDummyData?['brandPercentage'];

    if (percentage == null) {
      return 0;
    }

    return (percentage as num).toDouble();
  }

  // ===========================================================================
  // PREVIOUS MONTH DATA
  // ===========================================================================
  //
  // September 2026 compares against August 2026.
  //
  // ===========================================================================

  double get _previousMonthSpending {
    return 180.00;
  }

  double get _previousMonthLitres {
    return 55.0;
  }

  int get _previousMonthRefuels {
    return 6;
  }

  // ===========================================================================
  // CURRENT MONTH COMPARISON
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

  // ===========================================================================
  // PETROL BRAND ANALYSIS - REAL CURRENT MONTH
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

    if (_mostUsedBrand == 'Not available' ||
        _mostUsedBrand == 'No data') {
      return 0;
    }

    return (_mostUsedBrandCount / _currentMonthRefuels) *
        100;
  }

  // ===========================================================================
  // AI ANALYSIS
  // ===========================================================================

  Map<String, int> get _currentMonthBrandCounts {
    final Map<String, int> brandCounts = {};

    for (final transaction in _currentMonthTransactions) {
      final brand = _detectBrandFromStationName(
        transaction.stationName,
      );

      if (brand != 'Unknown') {
        brandCounts[brand] = (brandCounts[brand] ?? 0) + 1;
      }
    }

    return brandCounts;
  }

  String get _currentMonthBrandBreakdown {
    final brandCounts = _currentMonthBrandCounts;

    if (brandCounts.isEmpty) {
      return 'No brand data available';
    }

    final total = _currentMonthRefuels;

    final sortedBrands = brandCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedBrands.map((entry) {
      final percentage = total == 0
          ? 0.0
          : (entry.value / total) * 100;

      return '${entry.key} ${percentage.toStringAsFixed(0)}%';
    }).join('\n');
  }
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
  // BUILD
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
  // ERROR
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
  // REPORT
  // ===========================================================================

  Widget _buildReport() {
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

        const SizedBox(height: 15),

        _buildMonthSelector(),

        const SizedBox(height: 18),

        _buildMonthlySummary(),

        const SizedBox(height: 20),

        // ---------------------------------------------------------------------
        // FUEL SPENDING
        // ---------------------------------------------------------------------

        _buildReportCard(
          icon: Icons.attach_money,
          title: 'Fuel Spending',
          value:
          'RM${_selectedSpending.toStringAsFixed(2)}',
          subtitle: _isSelectedCurrentMonth
              ? _buildSpendingSubtitle()
              : 'Fuel spending for $_selectedMonthName $_selectedYear',
          category: 'spending',
        ),

        const SizedBox(height: 14),

        // ---------------------------------------------------------------------
        // PETROL BRAND
        // ---------------------------------------------------------------------

        _buildReportCard(
          icon: Icons.business,
          title: 'Petrol Brand',
          value: _isSelectedCurrentMonth
              ? _currentMonthBrandBreakdown
              : _selectedBrand,
          subtitle: _isSelectedCurrentMonth
              ? '$_selectedRefuels refuelling transactions'
              : _selectedBrand == 'No data' ||
              _selectedBrand == 'Not available'
              ? 'Brand information is not available'
              : '${_selectedBrandPercentage.toStringAsFixed(0)}% of your refuelling transactions',
          category: 'brand',
        ),

        const SizedBox(height: 20),

        // ---------------------------------------------------------------------
        // ADDITIONAL STATISTICS
        // ---------------------------------------------------------------------

        _buildAdditionalStatistics(),
      ],
    );
  }

  // ===========================================================================
  // HEADER
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
        const Text(
          'View your fuel usage and insights',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MONTH SELECTOR
  // ===========================================================================

  Widget _buildMonthSelector() {
    final now = DateTime.now();

    final isCurrentMonth =
        _selectedYear == now.year &&
            _selectedMonth == now.month;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE4EBF2),
        ),
      ),
      child: Row(
        children: [
          // Previous month
          IconButton(
            onPressed: _goToPreviousMonth,
            icon: const Icon(
              Icons.chevron_left,
              color: Color(0xFF1687E8),
            ),
          ),

          // Selected month
          Expanded(
            child: Text(
              '$_selectedMonthName $_selectedYear',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF123A63),
              ),
            ),
          ),

          // Next month
          IconButton(
            onPressed:
            isCurrentMonth ? null : _goToNextMonth,
            icon: const Icon(
              Icons.chevron_right,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MONTHLY SUMMARY
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
                  'RM${_selectedSpending.toStringAsFixed(2)}',
                ),
              ),

              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.local_gas_station_outlined,
                  label: 'Refuels',
                  value: '$_selectedRefuels',
                ),
              ),

              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.water_drop_outlined,
                  label: 'Litres',
                  value:
                  '${_selectedLitres.toStringAsFixed(1)} L',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SUMMARY ITEM
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
  // SPENDING SUBTITLE
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
  // REPORT CARD
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
                foregroundColor:
                const Color(0xFF1687E8),
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
  // ADDITIONAL STATISTICS
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

          // -------------------------------------------------------------------
          // Average per refuelling
          // -------------------------------------------------------------------

          _buildStatisticRow(
            icon: Icons.receipt_long_outlined,
            title: 'Average per refuelling',
            value:
            'RM${_selectedAverageSpending.toStringAsFixed(2)}',
          ),

          const Divider(height: 24),

          // -------------------------------------------------------------------
          // Total fuel purchased
          // -------------------------------------------------------------------

          _buildStatisticRow(
            icon: Icons.water_drop_outlined,
            title: 'Total fuel purchased',
            value:
            '${_selectedLitres.toStringAsFixed(2)} L',
          ),

          const Divider(height: 24),

          // -------------------------------------------------------------------
          // Total refuels
          // -------------------------------------------------------------------

          _buildStatisticRow(
            icon: Icons.local_gas_station_outlined,
            title: 'Total refuels',
            value: '$_selectedRefuels',
          ),

          // -------------------------------------------------------------------
          // Historical month information
          // -------------------------------------------------------------------
          //
          // For July and August, these values belong to the
          // selected month itself.
          //
          // For September, these are the previous month comparison.
          //
          // -------------------------------------------------------------------

          if (_isSelectedCurrentMonth) ...[
            const Divider(height: 24),

            _buildStatisticRow(
              icon: Icons.trending_up,
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
          ] else if (_selectedDummyData != null) ...[
            const Divider(height: 24),

            _buildStatisticRow(
              icon: Icons.calendar_month_outlined,
              title: 'Report month',
              value:
              '$_selectedMonthName $_selectedYear',
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // STATISTIC ROW
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
          textAlign: TextAlign.right,
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
  // MONTH NAME
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