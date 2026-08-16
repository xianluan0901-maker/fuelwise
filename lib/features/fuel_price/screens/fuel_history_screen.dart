import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fuel_price_model.dart';
import '../services/fuel_price_service.dart';
import '../widgets/fuel_trend_chart.dart';

class FuelHistoryScreen extends StatefulWidget {
  const FuelHistoryScreen({super.key});

  @override
  State<FuelHistoryScreen> createState() {
    return _FuelHistoryScreenState();
  }
}

class _FuelHistoryScreenState extends State<FuelHistoryScreen> {
  final FuelPriceService _service = FuelPriceService();

  List<FuelPrice> _history = [];

  // Users may select one, two or all three fuels.
  final Set<String> _selectedFuels = {'RON95'};

  int _selectedDays = 30;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final history = await _service.getFuelPriceHistory();

      if (!mounted) return;

      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
        'Unable to load fuel-price history. Please check your connection.';
      });
    }
  }

  List<FuelPrice> get _filteredHistory {
    if (_history.isEmpty) {
      return [];
    }

    // The service returns the newest record first.
    final newestDate = _history.first.date;

    final cutoffDate = newestDate.subtract(
      Duration(days: _selectedDays),
    );

    return _history.where((price) {
      return !price.date.isBefore(cutoffDate);
    }).toList();
  }

  double _priceFor(
      FuelPrice price,
      String fuelType,
      ) {
    switch (fuelType) {
      case 'RON97':
        return price.ron97;

      case 'Diesel':
      // This uses the Peninsular Malaysia diesel price.
        return price.diesel;

      case 'RON95':
      default:
        return price.ron95;
    }
  }

  Color _fuelColor(String fuelType) {
    switch (fuelType) {
      case 'RON97':
        return const Color(0xFF14A6A6);

      case 'Diesel':
        return const Color(0xFF7B61D1);

      case 'RON95':
      default:
        return const Color(0xFF3563FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE1F2FF),
        title: const Text(
          'Fuel Price History',
          style: TextStyle(
            color: Color(0xFF153B60),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 130),
          const Icon(
            Icons.wifi_off_rounded,
            size: 55,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 14),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF536B7E),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ),
        ],
      );
    }

    final filteredHistory = _filteredHistory;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        _buildFuelSelector(),
        const SizedBox(height: 16),
        _buildChartSection(filteredHistory),
        const SizedBox(height: 18),
        _buildAnalysisSection(filteredHistory),
        const SizedBox(height: 22),
        const Text(
          'Price History',
          style: TextStyle(
            color: Color(0xFF153B60),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _buildHistoryHeader(),
        const SizedBox(height: 5),
        _buildHistoryList(filteredHistory),
      ],
    );
  }

  Widget _buildFuelSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 7,
        runSpacing: 7,
        children: ['RON95', 'RON97', 'Diesel'].map((fuelType) {
          final selected = _selectedFuels.contains(fuelType);
          final colour = _fuelColor(fuelType);

          return FilterChip(
            label: Text(fuelType),
            selected: selected,
            showCheckmark: true,
            selectedColor: colour,
            checkmarkColor: Colors.white,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selected ? Colors.white : colour,
              fontWeight: FontWeight.bold,
            ),
            side: BorderSide(
              color: selected
                  ? colour
                  : colour.withValues(alpha: 0.25),
            ),
            onSelected: (shouldSelect) {
              setState(() {
                if (shouldSelect) {
                  _selectedFuels.add(fuelType);
                } else if (_selectedFuels.length > 1) {
                  // Do not allow all fuels to be deselected.
                  _selectedFuels.remove(fuelType);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartSection(
      List<FuelPrice> filteredHistory,
      ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Price (RM/L)',
                style: TextStyle(
                  color: Color(0xFF153B60),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedDays,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: 30,
                        child: Text('30 days'),
                      ),
                      DropdownMenuItem(
                        value: 90,
                        child: Text('90 days'),
                      ),
                      DropdownMenuItem(
                        value: 180,
                        child: Text('6 months'),
                      ),
                      DropdownMenuItem(
                        value: 365,
                        child: Text('1 year'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDays = value;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 270,
            child: FuelTrendChart(
              prices: filteredHistory,
              fuelTypes: _selectedFuels.toList(),
            ),
          ),
          const SizedBox(height: 12),
          _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      runSpacing: 8,
      children: _selectedFuels.map((fuelType) {
        final colour = _fuelColor(fuelType);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 15,
              height: 4,
              decoration: BoxDecoration(
                color: colour,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              fuelType,
              style: const TextStyle(
                color: Color(0xFF536B7E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAnalysisSection(
      List<FuelPrice> filteredHistory,
      ) {
    if (filteredHistory.length < 2) {
      return const SizedBox.shrink();
    }

    // History is newest first.
    final newest = filteredHistory.first;
    final oldest = filteredHistory.last;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE7EDF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Color(0xFF3563FF),
              ),
              SizedBox(width: 8),
              Text(
                'Trend Analysis',
                style: TextStyle(
                  color: Color(0xFF153B60),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          for (final fuelType in _selectedFuels)
            _buildFuelAnalysis(
              fuelType: fuelType,
              latestPrice: _priceFor(newest, fuelType),
              oldestPrice: _priceFor(oldest, fuelType),
            ),
        ],
      ),
    );
  }

  Widget _buildFuelAnalysis({
    required String fuelType,
    required double latestPrice,
    required double oldestPrice,
  }) {
    final difference = latestPrice - oldestPrice;

    final percentage = oldestPrice == 0
        ? 0.0
        : (difference / oldestPrice) * 100;

    const tolerance = 0.001;
    final unchanged = difference.abs() < tolerance;
    final increased = difference > 0;

    final colour = unchanged
        ? Colors.grey
        : increased
        ? Colors.redAccent
        : const Color(0xFF3563FF);

    final description = unchanged
        ? '$fuelType remained unchanged during this period.'
        : '$fuelType ${increased ? 'increased' : 'decreased'} by '
        'RM${difference.abs().toStringAsFixed(2)} '
        'during this period.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: _fuelColor(fuelType),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 54,
            child: Text(
              fuelType,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 68,
            child: Text(
              unchanged
                  ? '0.0%'
                  : '${increased ? '+' : ''}'
                  '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: colour,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: Color(0xFF718096),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFE2F0FF),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'Date',
              style: TextStyle(
                color: Color(0xFF153B60),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            'Price / Change',
            style: TextStyle(
              color: Color(0xFF153B60),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(
      List<FuelPrice> filteredHistory,
      ) {
    if (filteredHistory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(
          child: Text('No history available'),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE7EDF3),
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          for (
          int index = 0;
          index < filteredHistory.length;
          index++
          )
            _buildHistoryRow(
              filteredHistory: filteredHistory,
              index: index,
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow({
    required List<FuelPrice> filteredHistory,
    required int index,
  }) {
    final current = filteredHistory[index];

    final FuelPrice? previous =
    index + 1 < filteredHistory.length
        ? filteredHistory[index + 1]
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        border: index == filteredHistory.length - 1
            ? null
            : const Border(
          bottom: BorderSide(
            color: Color(0xFFE7EDF3),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              DateFormat('d MMM yyyy').format(current.date),
              style: const TextStyle(
                color: Color(0xFF536B7E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final fuelType in _selectedFuels)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _fuelColor(fuelType),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 48,
                        child: Text(
                          fuelType,
                          style: const TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 10,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 61,
                        child: Text(
                          'RM ${_priceFor(current, fuelType).toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: _fuelColor(fuelType),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),

                      if (previous != null)
                        _buildChangeIndicator(
                          _priceFor(current, fuelType) -
                              _priceFor(previous, fuelType),
                        )
                      else
                        const SizedBox(
                          width: 52,
                          child: Text(
                            '—',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangeIndicator(double difference) {
    const tolerance = 0.001;

    if (difference.abs() < tolerance) {
      return const SizedBox(
        width: 52,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.remove,
              size: 14,
              color: Colors.grey,
            ),
            SizedBox(width: 3),
            Text(
              '0.00',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    final increased = difference > 0;

    final colour = increased
        ? Colors.redAccent
        : const Color(0xFF3563FF);

    return SizedBox(
      width: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            increased
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 14,
            color: colour,
          ),
          const SizedBox(width: 2),
          Text(
            difference.abs().toStringAsFixed(2),
            style: TextStyle(
              color: colour,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}