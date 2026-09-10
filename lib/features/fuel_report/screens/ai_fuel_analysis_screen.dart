import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../payment/services/payment_service.dart';
import '../../payment/models/payment_model.dart';

class AIFuelAnalysisScreen extends StatefulWidget {
  final String category;

  const AIFuelAnalysisScreen({
    super.key,
    required this.category,
  });

  @override
  State<AIFuelAnalysisScreen> createState() =>
      _AIFuelAnalysisScreenState();
}

class _AIFuelAnalysisScreenState
    extends State<AIFuelAnalysisScreen> {
  final PaymentService _paymentService = PaymentService();

  bool _isLoading = true;
  String? _analysis;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAIAnalysis();
  }

  // ===========================================================================
  // LOAD AI ANALYSIS
  // ===========================================================================

  Future<void> _loadAIAnalysis() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please login to use AI fuel analysis.');
      }

      // -----------------------------------------------------------------------
      // Get data for the selected category
      // -----------------------------------------------------------------------

      final data = await _getCategoryData(user.id);

      // -----------------------------------------------------------------------
      // Send data to Supabase Edge Function
      // -----------------------------------------------------------------------

      final response = await supabase.functions.invoke(
        'fuel-ai-analysis',
        body: {
          'category': widget.category,
          'data': data,
        },
      );

      if (!mounted) return;

      final responseData = response.data;

      if (responseData == null) {
        throw Exception('No response from AI service.');
      }

      if (responseData['success'] != true) {
        throw Exception(
          responseData['error']?.toString() ??
              'Unable to generate AI analysis.',
        );
      }

      setState(() {
        _analysis = responseData['analysis']?.toString();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ===========================================================================
  // GET CATEGORY DATA
  // ===========================================================================
  Future<Map<String, dynamic>> _getCategoryData(
      String userId,
      ) async {
    switch (widget.category) {
      case 'spending':
        return await _getRealSpendingData(userId);

      case 'fuelType':
        return _getDemoFuelTypeData();

      case 'station':
        return _getDemoStationData();

      case 'brand':
        return await _getRealBrandData(userId);

      default:
        return await _getRealSpendingData(userId);
    }
  }


  // ===========================================================================
  // REAL SPENDING DATA
  // ===========================================================================

  Future<Map<String, dynamic>> _getRealSpendingData(
      String userId,
      ) async {
    // Get all real payment transactions from Supabase.
    final transactions =
    await _paymentService.getTransactionHistory(userId);

    final now = DateTime.now();

    // -------------------------------------------------------------------------
    // Current month
    // -------------------------------------------------------------------------

    final startOfCurrentMonth = DateTime(
      now.year,
      now.month,
      1,
    );

    final startOfNextMonth = DateTime(
      now.year,
      now.month + 1,
      1,
    );

    final currentMonthTransactions =
    transactions.where((transaction) {
      final date = transaction.createdAt;

      return !date.isBefore(startOfCurrentMonth) &&
          date.isBefore(startOfNextMonth);
    }).toList();

    // -------------------------------------------------------------------------
    // Calculate current month values
    // -------------------------------------------------------------------------

    double currentSpending = 0.0;
    double currentLitres = 0.0;

    for (final transaction in currentMonthTransactions) {
      currentSpending += transaction.totalAmount;
      currentLitres += transaction.quantityLiters;
    }

    final currentRefuels =
        currentMonthTransactions.length;

    // -------------------------------------------------------------------------
    // Previous month
    //
    // Temporary baseline from your Fuel Report.
    // We will replace this with real previous-month data later.
    // -------------------------------------------------------------------------

    const double previousSpending = 180.00;
    const double previousLitres = 55.0;
    const int previousRefuels = 6;

    // -------------------------------------------------------------------------
    // Calculate changes
    // -------------------------------------------------------------------------

    final spendingDifference =
        currentSpending - previousSpending;

    final spendingPercentageChange =
    previousSpending == 0
        ? 0.0
        : (spendingDifference / previousSpending) * 100;

    final litresDifference =
        currentLitres - previousLitres;

    final litresPercentageChange =
    previousLitres == 0
        ? 0.0
        : (litresDifference / previousLitres) * 100;

    final refuelsDifference =
        currentRefuels - previousRefuels;

    final refuelsPercentageChange =
    previousRefuels == 0
        ? 0.0
        : (refuelsDifference / previousRefuels) * 100;

    // -------------------------------------------------------------------------
    // Suggested next-month target
    //
    // This is calculated by the application, NOT invented by Gemini.
    // -------------------------------------------------------------------------

    double targetMin;
    double targetMax;

    if (currentSpending > previousSpending) {
      targetMin = previousSpending;
      targetMax = previousSpending * 1.20;
    } else if (currentSpending < previousSpending) {
      targetMin = currentSpending;
      targetMax = currentSpending * 1.10;
    } else {
      targetMin = currentSpending;
      targetMax = currentSpending * 1.10;
    }

    return {
      'current_month': {
        'spending': double.parse(
          currentSpending.toStringAsFixed(2),
        ),
        'refuels': currentRefuels,
        'litres': double.parse(
          currentLitres.toStringAsFixed(2),
        ),
      },

      'previous_month': {
        'spending': previousSpending,
        'refuels': previousRefuels,
        'litres': previousLitres,
      },

      'comparison': {
        'spending_difference': double.parse(
          spendingDifference.toStringAsFixed(2),
        ),
        'spending_change_percentage': double.parse(
          spendingPercentageChange.toStringAsFixed(1),
        ),
        'litres_difference': double.parse(
          litresDifference.toStringAsFixed(2),
        ),
        'litres_change_percentage': double.parse(
          litresPercentageChange.toStringAsFixed(1),
        ),
        'refuels_difference': refuelsDifference,
        'refuels_change_percentage': double.parse(
          refuelsPercentageChange.toStringAsFixed(1),
        ),
      },

      'recommendation': {
        'target_min': double.parse(
          targetMin.toStringAsFixed(0),
        ),
        'target_max': double.parse(
          targetMax.toStringAsFixed(0),
        ),
        'basis': 'Based on the user\'s recorded spending pattern.',
      },

      'limitations': [
        'Travel distance is not available.',
        'Vehicle fuel efficiency cannot be determined.',
        'Analysis is based on recorded fuel transactions.',
      ],
    };
  }

  // ===========================================================================
  // TEMPORARY DEMO DATA
  //
  // These will be replaced with REAL data later.
  // ===========================================================================

  Map<String, dynamic> _getDemoFuelTypeData() {
    return {
      'most_used_fuel_type': 'RON95',
      'percentage_of_refuels': 75,
      'total_refuels': 8,
    };
  }

  Map<String, dynamic> _getDemoStationData() {
    return {
      'most_used_station': 'Shell Taman ABC',
      'visits': 6,
      'total_refuels': 8,
    };
  }

  Future<Map<String, dynamic>> _getRealBrandData(
      String userId,
      ) async {
    final transactions =
    await _paymentService.getTransactionHistory(userId);

    final now = DateTime.now();

    final startOfCurrentMonth = DateTime(
      now.year,
      now.month,
      1,
    );

    final startOfNextMonth = DateTime(
      now.year,
      now.month + 1,
      1,
    );

    final currentMonthTransactions =
    transactions.where((transaction) {
      final date = transaction.createdAt;

      return !date.isBefore(startOfCurrentMonth) &&
          date.isBefore(startOfNextMonth);
    }).toList();

    // Count each petrol brand
    final Map<String, int> brandCounts = {};

    for (final transaction in currentMonthTransactions) {
      final brand = _detectBrand(
        transaction.stationName,
      );

      if (brand != 'Unknown') {
        brandCounts[brand] =
            (brandCounts[brand] ?? 0) + 1;
      }
    }

    final totalRefuels = currentMonthTransactions.length;

    // Calculate percentage for EVERY brand
    final Map<String, double> brandPercentages = {};

    for (final entry in brandCounts.entries) {
      brandPercentages[entry.key] =
      totalRefuels == 0
          ? 0
          : (entry.value / totalRefuels) * 100;
    }

    String mostUsedBrand = 'No data';

    if (brandCounts.isNotEmpty) {
      final highestCount = brandCounts.values.reduce(
            (a, b) => a > b ? a : b,
      );

      final topBrands = brandCounts.entries
          .where((entry) => entry.value == highestCount)
          .map((entry) => entry.key)
          .toList();

      if (topBrands.length == 1) {
        mostUsedBrand = topBrands.first;
      } else {
        mostUsedBrand = 'No single most used brand';
      }
    }

    return {
      'month':
      '${_monthName(now.month)} ${now.year}',
      'total_refuels': totalRefuels,
      'brand_counts': brandCounts,
      'brand_percentages': brandPercentages,
      'most_used_brand': mostUsedBrand,
    };
  }
  String _detectBrand(String stationName) {
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

  // ===========================================================================
  // CATEGORY TITLE
  // ===========================================================================

  String _categoryTitle() {
    switch (widget.category) {
      case 'spending':
        return 'Fuel Spending Analysis';

      case 'fuelType':
        return 'Fuel Type Analysis';

      case 'station':
        return 'Station Analysis';

      case 'brand':
        return 'Petrol Brand Analysis';

      default:
        return 'Fuel Analysis';
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _categoryTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1687E8),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  // ===========================================================================
  // BODY
  // ===========================================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF1687E8),
            ),
            SizedBox(height: 16),
            Text(
              'AI is analysing your fuel data...',
              style: TextStyle(
                color: Color(0xFF718096),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAIHeader(),

          const SizedBox(height: 20),

          _buildAnalysisCard(),

          const SizedBox(height: 20),

          _buildDisclaimer(),
        ],
      ),
    );
  }

  // ===========================================================================
  // AI HEADER
  // ===========================================================================

  Widget _buildAIHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF123A63),
            Color(0xFF1687E8),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 30,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Fuel Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Personalised analysis based on your fuel data',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ANALYSIS CARD
  // ===========================================================================

  Widget _buildAnalysisCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE4EBF2),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Color(0xFF1687E8),
              ),
              SizedBox(width: 8),
              Text(
                'AI Insight',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF123A63),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            _analysis ?? 'No analysis available.',
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF4A5568),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DISCLAIMER
  // ===========================================================================

  Widget _buildDisclaimer() {
    return const Text(
      'This AI analysis is generated from the fuel data recorded in FuelWise MY. '
          'It is intended to help you understand your fuel spending and usage patterns. '
          'Travel distance and vehicle fuel efficiency are not available in the current analysis.',
      style: TextStyle(
        fontSize: 12,
        color: Color(0xFF718096),
        height: 1.5,
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
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.redAccent,
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to generate AI analysis',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF123A63),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                  _analysis = null;
                });

                _loadAIAnalysis();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}