import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../payment/services/payment_service.dart';
import '../../payment/models/payment_model.dart';

class AIFuelAnalysisScreen extends StatefulWidget {
  final String category;

  // The month selected in Fuel Report
  final int selectedYear;
  final int selectedMonth;

  const AIFuelAnalysisScreen({
    super.key,
    required this.category,
    required this.selectedYear,
    required this.selectedMonth,
  });

  @override
  State<AIFuelAnalysisScreen> createState() =>
      _AIFuelAnalysisScreenState();
}

class _AIFuelAnalysisScreenState
    extends State<AIFuelAnalysisScreen> {
  final PaymentService _paymentService =
  PaymentService();

  bool _isLoading = true;
  String? _analysis;
  String? _error;

  // Real data used for displaying the UI
  Map<String, dynamic>? _analysisData;

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
      final supabase =
          Supabase.instance.client;

      final user =
          supabase.auth.currentUser;

      if (user == null) {
        throw Exception(
          'Please login to use AI fuel analysis.',
        );
      }

      final data =
      await _getCategoryData(user.id);

      debugPrint(
        '========================================',
      );

      debugPrint(
        'AI CATEGORY: ${widget.category}',
      );

      debugPrint(
        'AI SELECTED MONTH: '
            '${_monthName(widget.selectedMonth)} '
            '${widget.selectedYear}',
      );

      debugPrint(
        'AI DATA: $data',
      );

      debugPrint(
        '========================================',
      );

      final response =
      await supabase.functions.invoke(
        'fuel-ai-analysis',
        body: {
          'category': widget.category,

          // VERY IMPORTANT:
          // Tell the Edge Function exactly which
          // month the user selected.
          'selected_year':
          widget.selectedYear,

          'selected_month':
          widget.selectedMonth,

          'data': data,
        },
      );

      if (!mounted) return;

      final responseData =
          response.data;

      if (responseData == null) {
        throw Exception(
          'No response from AI service.',
        );
      }

      if (responseData['success'] != true) {
        throw Exception(
          responseData['error']?.toString() ??
              'Unable to generate AI analysis.',
        );
      }

      setState(() {
        _analysis =
            responseData['analysis']
                ?.toString();

        _analysisData = data;

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

  Future<Map<String, dynamic>>
  _getCategoryData(
      String userId,
      ) async {
    switch (widget.category) {
      case 'spending':
        return await _getRealSpendingData(
          userId,
        );

      case 'fuelType':
        return await _getRealFuelTypeData(
          userId,
        );

      case 'station':
        return await _getRealStationData(
          userId,
        );

      case 'brand':
        return await _getRealBrandData(
          userId,
        );

      default:
        return await _getRealSpendingData(
          userId,
        );
    }
  }

  // ===========================================================================
  // GET TRANSACTIONS FOR EXACT MONTH
  // ===========================================================================

  List<PaymentTransaction>
  _getTransactionsForMonth(
      List<PaymentTransaction> transactions,
      int year,
      int month,
      ) {
    return transactions.where((transaction) {
      final date =
          transaction.createdAt;

      return date.year == year &&
          date.month == month;
    }).toList();
  }

  // ===========================================================================
  // REAL SPENDING DATA
  // ===========================================================================

  Future<Map<String, dynamic>>
  _getRealSpendingData(
      String userId,
      ) async {
    try {
      final transactions =
      await _paymentService
          .getTransactionHistory(
        userId,
      );

      // =======================================================================
      // SELECTED MONTH
      // =======================================================================

      final selectedTransactions =
      _getTransactionsForMonth(
        transactions,
        widget.selectedYear,
        widget.selectedMonth,
      );

      // =======================================================================
      // PREVIOUS MONTH
      // =======================================================================

      final previousMonthDate =
      DateTime(
        widget.selectedYear,
        widget.selectedMonth - 1,
        1,
      );

      final previousTransactions =
      _getTransactionsForMonth(
        transactions,
        previousMonthDate.year,
        previousMonthDate.month,
      );

      // =======================================================================
      // SELECTED MONTH SPENDING
      // =======================================================================

      double selectedSpending = 0.0;
      double selectedLitres = 0.0;

      for (final transaction
      in selectedTransactions) {
        selectedSpending +=
            transaction.totalAmount;

        selectedLitres +=
            transaction.quantityLiters;
      }

      final selectedRefuels =
          selectedTransactions.length;

      // =======================================================================
      // PREVIOUS MONTH SPENDING
      // =======================================================================

      double previousSpending = 0.0;
      double previousLitres = 0.0;

      for (final transaction
      in previousTransactions) {
        previousSpending +=
            transaction.totalAmount;

        previousLitres +=
            transaction.quantityLiters;
      }

      final previousRefuels =
          previousTransactions.length;

      // =======================================================================
      // BRAND DATA
      // =======================================================================

      final selectedBrandCounts =
      _calculateBrandCounts(
        selectedTransactions,
      );

      final selectedBrandPercentages =
      _calculateBrandPercentages(
        selectedBrandCounts,
        selectedRefuels,
      );

      final selectedMostUsedBrand =
      _getMostUsedBrand(
        selectedBrandCounts,
      );

      final previousBrandCounts =
      _calculateBrandCounts(
        previousTransactions,
      );

      final previousBrandPercentages =
      _calculateBrandPercentages(
        previousBrandCounts,
        previousRefuels,
      );

      final previousMostUsedBrand =
      _getMostUsedBrand(
        previousBrandCounts,
      );

      // =======================================================================
      // COMPARISON
      // =======================================================================

      final spendingDifference =
          selectedSpending -
              previousSpending;

      final litresDifference =
          selectedLitres -
              previousLitres;

      final refuelsDifference =
          selectedRefuels -
              previousRefuels;

      final spendingPercentage =
      previousSpending == 0
          ? 0.0
          : (spendingDifference /
          previousSpending) *
          100;

      final litresPercentage =
      previousLitres == 0
          ? 0.0
          : (litresDifference /
          previousLitres) *
          100;

      final refuelsPercentage =
      previousRefuels == 0
          ? 0.0
          : (refuelsDifference /
          previousRefuels) *
          100;

      // =======================================================================
      // TREND
      // =======================================================================

      String spendingTrend;

      if (selectedSpending >
          previousSpending) {
        spendingTrend = 'increased';
      } else if (selectedSpending <
          previousSpending) {
        spendingTrend = 'decreased';
      } else {
        spendingTrend =
        'remained the same';
      }

      // =======================================================================
      // GENERAL RECOMMENDATION
      // =======================================================================

      String recommendation;

      if (selectedSpending >
          previousSpending &&
          previousSpending > 0) {
        recommendation =
        'Your fuel spending increased compared with '
            '${_monthName(previousMonthDate.month)} '
            '${previousMonthDate.year}. '
            'Monitor your refuelling frequency and spending.';
      } else if (selectedSpending <
          previousSpending) {
        recommendation =
        'Your fuel spending decreased compared with '
            '${_monthName(previousMonthDate.month)} '
            '${previousMonthDate.year}. '
            'Keep maintaining your current spending habits.';
      } else {
        recommendation =
        'Continue monitoring your fuel spending '
            'to understand your monthly fuel habits.';
      }

      // =======================================================================
      // RETURN REAL DATA
      // =======================================================================

      return {
        // Selected month
        'selected_month': {
          'month':
          '${_monthName(widget.selectedMonth)} '
              '${widget.selectedYear}',

          'year':
          widget.selectedYear,

          'month_number':
          widget.selectedMonth,

          'spending':
          selectedSpending,

          'litres':
          selectedLitres,

          'refuels':
          selectedRefuels,

          'most_used_brand':
          selectedMostUsedBrand,

          'brand_counts':
          selectedBrandCounts,

          'brand_percentages':
          selectedBrandPercentages,
        },

        // Kept for Edge Function compatibility.
        // IMPORTANT: this is the SELECTED MONTH,
        // NOT DateTime.now().
        'current_month': {
          'month':
          '${_monthName(widget.selectedMonth)} '
              '${widget.selectedYear}',

          'spending':
          selectedSpending,

          'litres':
          selectedLitres,

          'refuels':
          selectedRefuels,

          'most_used_brand':
          selectedMostUsedBrand,

          'brand_counts':
          selectedBrandCounts,

          'brand_percentages':
          selectedBrandPercentages,
        },

        // Previous month relative to selected month
        'previous_month': {
          'month':
          '${_monthName(previousMonthDate.month)} '
              '${previousMonthDate.year}',

          'spending':
          previousSpending,

          'litres':
          previousLitres,

          'refuels':
          previousRefuels,

          'most_used_brand':
          previousMostUsedBrand,

          'brand_counts':
          previousBrandCounts,

          'brand_percentages':
          previousBrandPercentages,
        },

        'comparison': {
          'spending_difference':
          spendingDifference,

          'spending_percentage':
          spendingPercentage,

          'litres_difference':
          litresDifference,

          'litres_percentage':
          litresPercentage,

          'refuels_difference':
          refuelsDifference,

          'refuels_percentage':
          refuelsPercentage,
        },

        'trend':
        spendingTrend,

        'recommendation':
        recommendation,

        'source':
        'Supabase transaction history',

        'limitations':
        'Analysis is based only on recorded fuel '
            'transactions in the database.',
      };
    } catch (e) {
      debugPrint(
        'Error getting real spending data: $e',
      );

      rethrow;
    }
  }

  // ===========================================================================
  // REAL PETROL BRAND DATA
  // ===========================================================================

  Future<Map<String, dynamic>>
  _getRealBrandData(
      String userId,
      ) async {
    final transactions =
    await _paymentService
        .getTransactionHistory(
      userId,
    );

    // =======================================================================
    // SELECTED MONTH
    // =======================================================================

    final selectedTransactions =
    _getTransactionsForMonth(
      transactions,
      widget.selectedYear,
      widget.selectedMonth,
    );

    // =======================================================================
    // PREVIOUS MONTH
    // =======================================================================

    final previousMonthDate =
    DateTime(
      widget.selectedYear,
      widget.selectedMonth - 1,
      1,
    );

    final previousTransactions =
    _getTransactionsForMonth(
      transactions,
      previousMonthDate.year,
      previousMonthDate.month,
    );

    // =======================================================================
    // SELECTED MONTH BRAND COUNTS
    // =======================================================================

    final selectedBrandCounts =
    _calculateBrandCounts(
      selectedTransactions,
    );

    final selectedTotalRefuels =
        selectedTransactions.length;

    final selectedBrandPercentages =
    _calculateBrandPercentages(
      selectedBrandCounts,
      selectedTotalRefuels,
    );

    final selectedMostUsedBrand =
    _getMostUsedBrand(
      selectedBrandCounts,
    );

    // =======================================================================
    // PREVIOUS MONTH BRAND COUNTS
    // =======================================================================

    final previousBrandCounts =
    _calculateBrandCounts(
      previousTransactions,
    );

    final previousTotalRefuels =
        previousTransactions.length;

    final previousBrandPercentages =
    _calculateBrandPercentages(
      previousBrandCounts,
      previousTotalRefuels,
    );

    final previousMostUsedBrand =
    _getMostUsedBrand(
      previousBrandCounts,
    );

    // =======================================================================
    // DEBUG
    // =======================================================================

    debugPrint(
      '========================================',
    );

    debugPrint(
      'PETROL BRAND ANALYSIS',
    );

    debugPrint(
      'SELECTED MONTH: '
          '${_monthName(widget.selectedMonth)} '
          '${widget.selectedYear}',
    );

    debugPrint(
      'SELECTED TOTAL TRANSACTIONS: '
          '$selectedTotalRefuels',
    );

    debugPrint(
      'SELECTED BRAND COUNTS: '
          '$selectedBrandCounts',
    );

    debugPrint(
      'SELECTED BRAND PERCENTAGES: '
          '$selectedBrandPercentages',
    );

    debugPrint(
      'PREVIOUS MONTH: '
          '${_monthName(previousMonthDate.month)} '
          '${previousMonthDate.year}',
    );

    debugPrint(
      'PREVIOUS TOTAL TRANSACTIONS: '
          '$previousTotalRefuels',
    );

    debugPrint(
      'PREVIOUS BRAND COUNTS: '
          '$previousBrandCounts',
    );

    debugPrint(
      '========================================',
    );

    // =======================================================================
    // RETURN DATA
    // =======================================================================

    return {
      'selected_month': {
        'month':
        '${_monthName(widget.selectedMonth)} '
            '${widget.selectedYear}',

        'year':
        widget.selectedYear,

        'month_number':
        widget.selectedMonth,

        'total_refuels':
        selectedTotalRefuels,

        'brand_counts':
        selectedBrandCounts,

        'brand_percentages':
        selectedBrandPercentages,

        'most_used_brand':
        selectedMostUsedBrand,
      },

      // Compatibility with Edge Function
      // This is ALSO the selected month.
      'current_month': {
        'month':
        '${_monthName(widget.selectedMonth)} '
            '${widget.selectedYear}',

        'total_refuels':
        selectedTotalRefuels,

        'brand_counts':
        selectedBrandCounts,

        'brand_percentages':
        selectedBrandPercentages,

        'most_used_brand':
        selectedMostUsedBrand,
      },

      'previous_month': {
        'month':
        '${_monthName(previousMonthDate.month)} '
            '${previousMonthDate.year}',

        'total_refuels':
        previousTotalRefuels,

        'brand_counts':
        previousBrandCounts,

        'brand_percentages':
        previousBrandPercentages,

        'most_used_brand':
        previousMostUsedBrand,
      },

      'source':
      'Supabase transaction history',

      'note':
      'Petrol brand is detected from the recorded station name.',
    };
  }

  // ===========================================================================
  // CALCULATE BRAND COUNTS
  // ===========================================================================

  Map<String, int> _calculateBrandCounts(
      List<PaymentTransaction> transactions,
      ) {
    final Map<String, int>
    brandCounts = {};

    for (final transaction
    in transactions) {
      final brand =
      _detectBrand(
        transaction.stationName,
      );

      if (brand != 'Unknown') {
        brandCounts[brand] =
            (brandCounts[brand] ?? 0) + 1;
      }
    }

    return brandCounts;
  }

  // ===========================================================================
  // CALCULATE BRAND PERCENTAGES
  // ===========================================================================

  Map<String, double>
  _calculateBrandPercentages(
      Map<String, int> brandCounts,
      int totalRefuels,
      ) {
    final Map<String, double>
    percentages = {};

    for (final entry
    in brandCounts.entries) {
      percentages[entry.key] =
      totalRefuels == 0
          ? 0.0
          : (entry.value /
          totalRefuels) *
          100;
    }

    return percentages;
  }

  // ===========================================================================
  // GET MOST USED BRAND
  // ===========================================================================

  String _getMostUsedBrand(Map<String, int> brandCounts) {
    if (brandCounts.isEmpty) {
      return 'No data';
    }

    final highestCount = brandCounts.values.reduce(
          (a, b) => a > b ? a : b,
    );

    final topBrands = brandCounts.entries
        .where((entry) => entry.value == highestCount)
        .map((entry) => entry.key)
        .toList();

    return topBrands.join(' & ');
  }

  // ===========================================================================
  // DETECT BRAND FROM STATION NAME
  // ===========================================================================

  String _detectBrand(
      String stationName,
      ) {
    final name =
    stationName.toLowerCase();

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

  // ===========================================================================
  // REAL STATION DATA
  // ===========================================================================

  Future<Map<String, dynamic>>
  _getRealStationData(
      String userId,
      ) async {
    final transactions =
    await _paymentService
        .getTransactionHistory(
      userId,
    );

    final selectedTransactions =
    _getTransactionsForMonth(
      transactions,
      widget.selectedYear,
      widget.selectedMonth,
    );

    final Map<String, int>
    stationCounts = {};

    for (final transaction
    in selectedTransactions) {
      final station =
      transaction.stationName.trim();

      if (station.isEmpty) {
        continue;
      }

      stationCounts[station] =
          (stationCounts[station] ?? 0) + 1;
    }

    String mostUsedStation =
        'No data';

    int highestVisits = 0;

    for (final entry
    in stationCounts.entries) {
      if (entry.value >
          highestVisits) {
        highestVisits =
            entry.value;

        mostUsedStation =
            entry.key;
      }
    }

    return {
      'selected_month': {
        'month':
        '${_monthName(widget.selectedMonth)} '
            '${widget.selectedYear}',

        'most_used_station':
        mostUsedStation,

        'visits':
        highestVisits,

        'total_refuels':
        selectedTransactions.length,

        'station_counts':
        stationCounts,
      },

      'source':
      'Supabase transaction history',
    };
  }

  // ===========================================================================
  // REAL FUEL TYPE DATA
  // ===========================================================================

  Future<Map<String, dynamic>>
  _getRealFuelTypeData(
      String userId,
      ) async {
    final transactions =
    await _paymentService
        .getTransactionHistory(
      userId,
    );

    final selectedTransactions =
    _getTransactionsForMonth(
      transactions,
      widget.selectedYear,
      widget.selectedMonth,
    );

    return {
      'selected_month': {
        'month':
        '${_monthName(widget.selectedMonth)} '
            '${widget.selectedYear}',

        'total_refuels':
        selectedTransactions.length,

        'fuel_type_data_available':
        false,

        'message':
        'Fuel type is not available in the recorded transaction data.',
      },

      'source':
      'Supabase transaction history',
    };
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
      backgroundColor:
      const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: Text(
          _categoryTitle(),
          style: const TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),


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
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color:
              Color(0xFF1687E8),
            ),

            SizedBox(height: 16),

            Text(
              'AI is analysing your fuel data...',
              style: TextStyle(
                color:
                Color(0xFF718096),
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

    // For Petrol Brand Analysis,
    // use our real Supabase data to build
    // the interface so the displayed month
    // and brand counts cannot be mismatched.
    if (widget.category == 'brand' &&
        _analysisData != null) {
      return _buildBrandAnalysis();
    }

    return _buildGeneralAnalysis();
  }

  // ===========================================================================
  // BRAND ANALYSIS UI
  // ===========================================================================

  Widget _buildBrandAnalysis() {
    final selected =
    _analysisData?['selected_month'];

    if (selected is! Map) {
      return _buildGeneralAnalysis();
    }

    final month =
        selected['month']?.toString() ??
            '${_monthName(widget.selectedMonth)} '
                '${widget.selectedYear}';

    final totalRefuels =
        (selected['total_refuels']
        as num?)
            ?.toInt() ??
            0;

    final mostUsedBrand =
        selected['most_used_brand']
            ?.toString() ??
            'No data';

    final brandCounts =
    selected['brand_counts'] is Map
        ? Map<String, dynamic>.from(
      selected['brand_counts'],
    )
        : <String, dynamic>{};

    final brandPercentages =
    selected['brand_percentages'] is Map
        ? Map<String, dynamic>.from(
      selected['brand_percentages'],
    )
        : <String, dynamic>{};

    return SingleChildScrollView(
      padding:
      const EdgeInsets.all(14),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _buildAIHeader(),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,

            padding:
            const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius:
              BorderRadius.circular(20),

              border: Border.all(
                color:
                const Color(0xFFE4EBF2),
              ),
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // ==========================================================
                // AI INSIGHT
                // ==========================================================

                const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color:
                      Color(0xFF1687E8),
                    ),

                    SizedBox(width: 8),

                    Text(
                      'AI Insight',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Color(0xFF123A63),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ==========================================================
                // BRAND USAGE SUMMARY
                // ==========================================================

                const Text(
                  'Brand Usage Summary',
                  style: TextStyle(
                    fontSize: 15,
                    color:
                    Color(0xFF4A5568),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  month,
                  style: const TextStyle(
                    fontSize: 14,
                    color:
                    Color(0xFF4A5568),
                  ),
                ),

                const SizedBox(height: 24),

                // ==========================================================
                // PRIMARY BRAND
                // ==========================================================

                Text(
                  'Primary Brand: $mostUsedBrand',
                  style: const TextStyle(
                    fontSize: 15,
                    color:
                    Color(0xFF4A5568),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _primaryBrandText(
                    mostUsedBrand,
                    brandCounts,
                    brandPercentages,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color:
                    Color(0xFF4A5568),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 26),

                // ==========================================================
                // SECONDARY BRANDS
                // ==========================================================

                if (brandCounts.length > 1) ...[
                  const Text(
                    'Secondary Brands:',
                    style: TextStyle(
                      fontSize: 15,
                      color:
                      Color(0xFF4A5568),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ..._buildSecondaryBrands(
                    brandCounts,
                    brandPercentages,
                    mostUsedBrand,
                  ),

                  const SizedBox(height: 24),
                ],

                // ==========================================================
                // TOTAL REFUELS
                // ==========================================================

                Text(
                  'Total Refuelling Trips: '
                      '$totalRefuels times',
                  style: const TextStyle(
                    fontSize: 15,
                    color:
                    Color(0xFF4A5568),
                  ),
                ),

                const SizedBox(height: 28),

                // ==========================================================
                // WHAT THIS MEANS
                // ==========================================================

                const Text(
                  'What this means',
                  style: TextStyle(
                    fontSize: 15,
                    color:
                    Color(0xFF4A5568),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  _buildBrandMeaning(
                    mostUsedBrand,
                    brandCounts,
                    totalRefuels,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color:
                    Color(0xFF4A5568),
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 28),

                // ==========================================================
                // TIP
                // ==========================================================

                const Text(
                  'Tip',
                  style: TextStyle(
                    fontSize: 15,
                    color:
                    Color(0xFF4A5568),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Compare fuel prices between nearby '
                      'stations before refuelling to make '
                      'a more informed choice.',
                  style: TextStyle(
                    fontSize: 15,
                    color:
                    Color(0xFF4A5568),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildDisclaimer(),
        ],
      ),
    );
  }

  // ===========================================================================
  // PRIMARY BRAND TEXT
  // ===========================================================================

  String _primaryBrandText(
      String brand,
      Map<String, dynamic> counts,
      Map<String, dynamic> percentages,
      ) {
    final count =
        (counts[brand] as num?)?.toInt() ??
            0;

    final percentage =
        (percentages[brand] as num?)
            ?.toDouble() ??
            0.0;

    if (count == 0) {
      return 'No recorded refuelling transactions for this brand.';
    }

    return 'Refuels: $count times '
        '(${percentage.toStringAsFixed(1)}%)';
  }

  // ===========================================================================
  // SECONDARY BRANDS
  // ===========================================================================

  List<Widget> _buildSecondaryBrands(
      Map<String, dynamic> counts,
      Map<String, dynamic> percentages,
      String primaryBrand,
      ) {
    final entries =
    counts.entries
        .where(
          (entry) =>
      entry.key != primaryBrand,
    )
        .toList();

    // Sort highest to lowest
    entries.sort(
          (a, b) {
        final aCount =
        (a.value as num).toInt();

        final bCount =
        (b.value as num).toInt();

        return bCount.compareTo(aCount);
      },
    );

    return entries.map((entry) {
      final brand =
          entry.key;

      final count =
      (entry.value as num).toInt();

      final percentage =
          (percentages[brand] as num?)
              ?.toDouble() ??
              0.0;

      return Padding(
        padding:
        const EdgeInsets.only(
          bottom: 8,
        ),

        child: Text(
          '$brand: $count refuels '
              '(${percentage.toStringAsFixed(1)}%)',

          style: const TextStyle(
            fontSize: 15,
            color:
            Color(0xFF4A5568),
          ),
        ),
      );
    }).toList();
  }

  // ===========================================================================
  // WHAT THIS MEANS
  // ===========================================================================

  String _buildBrandMeaning(
      String primaryBrand,
      Map<String, dynamic> counts,
      int totalRefuels,
      ) {
    final primaryCount =
        (counts[primaryBrand] as num?)
            ?.toInt() ??
            0;

    if (totalRefuels == 0) {
      return 'There are no recorded refuelling '
          'transactions for this month.';
    }

    if (primaryCount == totalRefuels) {
      return '$primaryBrand was your only recorded '
          'fuel brand this month, accounting for '
          'all $totalRefuels refuelling trips.';
    }

    return '$primaryBrand was your primary choice '
        'for most of your refuels, while occasionally '
        'using other fuel brands.';
  }

  // ===========================================================================
  // GENERAL AI ANALYSIS
  // ===========================================================================

  Widget _buildGeneralAnalysis() {
    return SingleChildScrollView(
      padding:
      const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _buildAIHeader(),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,

            padding:
            const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius:
              BorderRadius.circular(20),

              border: Border.all(
                color:
                const Color(0xFFE4EBF2),
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
                      color:
                      Color(0xFF1687E8),
                    ),

                    SizedBox(width: 8),

                    Text(
                      'AI Insight',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Color(0xFF123A63),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  _analysis ??
                      'No analysis available.',
                  style: const TextStyle(
                    fontSize: 15,
                    color:
                    Color(0xFF4A5568),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

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

      padding:
      const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient:
        const LinearGradient(
          colors: [
            Color(0xFF123A63),
            Color(0xFF1687E8),
          ],
        ),

        borderRadius:
        BorderRadius.circular(22),
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
                    fontWeight:
                    FontWeight.bold,
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
  // DISCLAIMER
  // ===========================================================================

  Widget _buildDisclaimer() {
    return const Text(
      'This analysis is based on fuel transactions '
          'recorded in FuelWise MY. Unrecorded transactions '
          'are not included.',

      style: TextStyle(
        fontSize: 12,
        color:
        Color(0xFF718096),
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
        padding:
        const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color:
              Colors.redAccent,
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to generate AI analysis',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
                color:
                Color(0xFF123A63),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _error ??
                  'Unknown error',
              textAlign:
              TextAlign.center,
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
                  _analysisData = null;
                });

                _loadAIAnalysis();
              },

              icon:
              const Icon(Icons.refresh),

              label:
              const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}