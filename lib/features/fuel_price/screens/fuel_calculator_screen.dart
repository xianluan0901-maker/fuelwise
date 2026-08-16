import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/fuel_price_model.dart';
import '../services/fuel_price_service.dart';

enum CalculatorMode {
  price,
  litre,
}

class FuelCalculatorScreen extends StatefulWidget {
  const FuelCalculatorScreen({super.key});

  @override
  State<FuelCalculatorScreen> createState() {
    return _FuelCalculatorScreenState();
  }
}

class _FuelCalculatorScreenState
    extends State<FuelCalculatorScreen> {
  final FuelPriceService _fuelPriceService =
  FuelPriceService();

  final TextEditingController _inputController =
  TextEditingController(text: '50.00');

  FuelPrice? _latestPrice;
  FuelPrice? _previousPrice;

  CalculatorMode _mode = CalculatorMode.price;

  bool _isEastMalaysia = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFuelPrices();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadFuelPrices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final history =
      await _fuelPriceService.getFuelPriceHistory();

      if (!mounted) return;

      setState(() {
        _latestPrice = history.first;
        _previousPrice =
        history.length >= 2 ? history[1] : history.first;

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
        'Unable to retrieve the latest fuel prices.';
      });
    }
  }

  double get _inputValue {
    return double.tryParse(
      _inputController.text.trim(),
    ) ??
        0;
  }

  double _priceFor(
      FuelPrice price,
      String fuelType,
      ) {
    switch (fuelType) {
      case 'BUDI95':
        return price.ron95Budi ?? price.ron95;

      case 'RON97':
        return price.ron97;

      case 'Diesel':
        return price.dieselForRegion(
          _isEastMalaysia,
        );

      case 'RON95':
      default:
        return price.ron95;
    }
  }

  double _litresFor(String fuelType) {
    if (_latestPrice == null || _inputValue <= 0) {
      return 0;
    }

    if (_mode == CalculatorMode.litre) {
      return _inputValue;
    }

    final pricePerLitre = _priceFor(
      _latestPrice!,
      fuelType,
    );

    if (pricePerLitre <= 0) {
      return 0;
    }

    return _inputValue / pricePerLitre;
  }

  double _totalFor(String fuelType) {
    if (_latestPrice == null || _inputValue <= 0) {
      return 0;
    }

    if (_mode == CalculatorMode.price) {
      return _inputValue;
    }

    final pricePerLitre = _priceFor(
      _latestPrice!,
      fuelType,
    );

    return _inputValue * pricePerLitre;
  }

  double _differenceFor(String fuelType) {
    if (_latestPrice == null ||
        _previousPrice == null) {
      return 0;
    }

    final currentPrice = _priceFor(
      _latestPrice!,
      fuelType,
    );

    final previousPrice = _priceFor(
      _previousPrice!,
      fuelType,
    );

    final weeklyPriceDifference =
        currentPrice - previousPrice;

    return weeklyPriceDifference *
        _litresFor(fuelType);
  }

  Color _fuelColour(String fuelType) {
    switch (fuelType) {
      case 'BUDI95':
        return const Color(0xFF1687E8);

      case 'RON97':
        return const Color(0xFFF5A623);

      case 'Diesel':
        return const Color(0xFF7B61D1);

      case 'RON95':
      default:
        return const Color(0xFF20A978);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE1F2FF),
        centerTitle: true,
        title: const Text(
          'Fuel Calculator',
          style: TextStyle(
            color: Color(0xFF153B60),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFuelPrices,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            12,
            18,
            12,
            45,
          ),
          children: [
            _buildInformationRow(),
            const SizedBox(height: 24),
            const Text(
              'Fuel Cost Calculator',
              style: TextStyle(
                color: Color(0xFF153B60),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildCalculatorCard(),
            const SizedBox(height: 28),
            const Text(
              'Result',
              style: TextStyle(
                color: Color(0xFF153B60),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationRow() {
    final date =
        _latestPrice?.date ?? DateTime.now();

    return Row(
      children: [
        const Icon(
          Icons.calendar_month_rounded,
          size: 18,
          color: Color(0xFF153B60),
        ),
        const SizedBox(width: 7),
        Text(
          DateFormat('d MMMM yyyy').format(date),
          style: const TextStyle(
            color: Color(0xFF153B60),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        PopupMenuButton<bool>(
          initialValue: _isEastMalaysia,
          onSelected: (isEast) {
            setState(() {
              _isEastMalaysia = isEast;
            });
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: false,
              child: Text('West Malaysia'),
            ),
            PopupMenuItem(
              value: true,
              child: Text('East Malaysia'),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE0E8F0),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF1687E8),
                ),
                const SizedBox(width: 4),
                Text(
                  _isEastMalaysia
                      ? 'East Malaysia'
                      : 'West Malaysia',
                  style: const TextStyle(
                    color: Color(0xFF536B7E),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFF718096),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatorCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFD7E8FF),
            Color(0xFFE8F1FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFCCDFFF),
        ),
      ),
      child: Column(
        children: [
          _buildModeSelector(),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Text(
                      _mode == CalculatorMode.price
                          ? 'RM'
                          : 'L',
                      style: const TextStyle(
                        color: Color(0xFF454B54),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 175,
                        ),
                        child: TextField(
                          controller: _inputController,
                          textAlign: TextAlign.center,
                          keyboardType:
                          const TextInputType
                              .numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(
                                r'^\d*\.?\d{0,2}',
                              ),
                            ),
                          ],
                          onChanged: (_) {
                            setState(() {});
                          },
                          style: const TextStyle(
                            color: Color(0xFF5B5BF7),
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: _mode ==
                                CalculatorMode.price
                                ? 'Enter RM'
                                : 'Enter litre',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9AA6B2),
                              fontSize: 14,
                              fontWeight:
                              FontWeight.normal,
                            ),
                            filled: true,
                            fillColor:
                            const Color(0xFFF6F7FF),
                            contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            enabledBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(10),
                              borderSide:
                              const BorderSide(
                                color:
                                Color(0xFFB9C5FF),
                                width: 1.4,
                              ),
                            ),
                            focusedBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(10),
                              borderSide:
                              const BorderSide(
                                color:
                                Color(0xFF5B5BF7),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF7B82C5),
                      size: 17,
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.touch_app_outlined,
                      color: Color(0xFF8A96A3),
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _mode == CalculatorMode.price
                          ? 'Enter your fuel budget'
                          : 'Enter the number of litres',
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              title: 'Price (RM)',
              mode: CalculatorMode.price,
            ),
          ),
          Expanded(
            child: _buildModeButton(
              title: 'Litre (L)',
              mode: CalculatorMode.litre,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String title,
    required CalculatorMode mode,
  }) {
    final selected = _mode == mode;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          _mode = mode;

          _inputController.text =
          mode == CalculatorMode.price
              ? '50.00'
              : '10.00';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected
                ? const Color(0xFF153B60)
                : const Color(0xFF7D8A99),
            fontSize: 12,
            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(35),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null ||
        _latestPrice == null) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Colors.redAccent,
              size: 35,
            ),
            const SizedBox(height: 9),
            Text(
              _errorMessage ??
                  'Fuel prices are unavailable.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadFuelPrices,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    const fuelTypes = [
      'RON95',
      'BUDI95',
      'RON97',
      'Diesel',
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Colors.white,
                Color(0xFFF7FAFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFDCE8F5),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF1687E8),
                    size: 21,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Fuel Comparison',
                    style: TextStyle(
                      color: Color(0xFF153B60),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                _mode == CalculatorMode.price
                    ? 'Litres purchasable with '
                    'RM${_inputValue.toStringAsFixed(2)}'
                    : 'Cost for '
                    '${_inputValue.toStringAsFixed(2)} litres',
                style: const TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 16),
              _buildResultTable(fuelTypes),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF718096),
              size: 15,
            ),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Difference is based on the change '
                    'from the previous weekly fuel price.',
                style: TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultTable(
      List<String> fuelTypes,
      ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(70),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(),
          4: FlexColumnWidth(),
        },
        border: const TableBorder(
          horizontalInside: BorderSide(
            color: Color(0xFFE5EDF5),
          ),
          verticalInside: BorderSide(
            color: Color(0xFFE5EDF5),
          ),
        ),
        children: [
          TableRow(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFDDEEFF),
                  Color(0xFFEDF6FF),
                ],
              ),
            ),
            children: [
              _buildHeaderCell(''),
              _buildHeaderCell('RON\n95'),
              _buildHeaderCell('BUDI\n95'),
              _buildHeaderCell('RON\n97'),
              _buildHeaderCell('DIESEL'),
            ],
          ),
          TableRow(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            children: [
              _buildLabelCell(
                icon:
                Icons.local_gas_station_rounded,
                label: 'Price',
                unit: 'RM/L',
              ),
              for (final fuel in fuelTypes)
                _buildValueCell(
                  _priceFor(
                    _latestPrice!,
                    fuel,
                  ).toStringAsFixed(2),
                  colour: _fuelColour(fuel),
                ),
            ],
          ),
          TableRow(
            decoration: const BoxDecoration(
              color: Color(0xFFF9FBFE),
            ),
            children: [
              _buildLabelCell(
                icon: Icons.water_drop_outlined,
                label: 'Litre',
                unit: 'L',
              ),
              for (final fuel in fuelTypes)
                _buildValueCell(
                  _litresFor(fuel)
                      .toStringAsFixed(2),
                ),
            ],
          ),
          TableRow(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            children: [
              _buildLabelCell(
                icon: Icons.payments_outlined,
                label: 'Total',
                unit: 'RM',
              ),
              for (final fuel in fuelTypes)
                _buildValueCell(
                  _totalFor(fuel)
                      .toStringAsFixed(2),
                  isBold: true,
                ),
            ],
          ),
          TableRow(
            decoration: const BoxDecoration(
              color: Color(0xFFF9FBFE),
            ),
            children: [
              _buildLabelCell(
                icon: Icons.trending_up_rounded,
                label: 'Change',
                unit: 'RM',
              ),
              for (final fuel in fuelTypes)
                _buildDifferenceCell(
                  _differenceFor(fuel),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      height: 43,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 4,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF153B60),
          fontSize: 12,
          height: 1.1,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLabelCell({
    required IconData icon,
    required String label,
    required String unit,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 13,
            color: const Color(0xFF718096),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF354B60),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  unit,
                  style: const TextStyle(
                    color: Color(0xFF93A1AF),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCell(
      String value, {
        Color colour = const Color(0xFF354B60),
        bool isBold = false,
      }) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colour,
          fontSize: 12,
          fontWeight: isBold
              ? FontWeight.bold
              : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDifferenceCell(
      double difference,
      ) {
    const tolerance = 0.001;

    if (difference.abs() < tolerance) {
      return Container(
        height: 48,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.remove_rounded,
              color: Colors.grey,
              size: 16,
            ),
            Text(
              '0.00',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
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

    return Container(
      height: 57,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(
            increased
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: colour,
            size: 14,
          ),
          Text(
            difference.abs().toStringAsFixed(2),
            style: TextStyle(
              color: colour,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}