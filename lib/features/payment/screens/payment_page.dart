// features/payment/screens/payment_page.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../vehicle/models/vehicle_model.dart';
import '../../vehicle/services/vehicle_service.dart';
import '../../vehicle/screens/vehicle_form_screen.dart';
import '../../fuel_price/services/fuel_price_service.dart';
import '../../fuel_price/models/fuel_price_model.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import 'payment_method_page.dart';

class PaymentPage extends StatefulWidget {
  final String placeId;
  final String stationName;
  final String? stationAddress;
  final String? stationBrand;

  final String? initialVehicleId;
  final String? initialFuelType;
  final double? initialLitres;
  final double? estimatedPricePerLitre;

  const PaymentPage({
    super.key,
    required this.placeId,
    required this.stationName,
    this.stationAddress,
    this.initialVehicleId,
    this.initialFuelType,
    this.initialLitres,
    this.estimatedPricePerLitre,
    this.stationBrand,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final PaymentService _paymentService = PaymentService();
  final VehicleService _vehicleService = VehicleService();
  final FuelPriceService _fuelPriceService = FuelPriceService();

  // ============================================================
  // State Variables
  // ============================================================

  Vehicle? _selectedVehicle;
  List<Vehicle> _vehicles = [];

  int? _pumpNumber;

  FuelType? _selectedFuelType;

  double _liters = 0;

  FuelPrice? _latestPrice;

  Voucher? _selectedVoucher;
  List<Voucher> _availableVouchers = [];

  int _userPoints = 0;
  int _pointsEarned = 0;

  bool _isLoading = true;
  bool _isProcessing = false;
  bool _estimateApplied = false;

  final TextEditingController _litersController =
  TextEditingController();

  // ============================================================
  // Computed Properties
  // ============================================================

  bool get _isEastMalaysia {
    final address = (widget.stationAddress ?? '').toLowerCase();

    return address.contains('sabah') ||
        address.contains('sarawak') ||
        address.contains('labuan');
  }

  String get _stationBrand {
    final station = widget.stationName.toLowerCase();

    if (station.contains('petronas')) {
      return 'petronas';
    }

    if (station.contains('shell')) {
      return 'shell';
    }

    if (station.contains('petron')) {
      return 'petron';
    }

    if (station.contains('caltex')) {
      return 'caltex';
    }

    if (station.contains('bhp')) {
      return 'bhp';
    }

    return '';
  }

  double get _pricePerLiter {
    if (_selectedFuelType == null || _latestPrice == null) {
      return 0;
    }

    switch (_selectedFuelType) {
      case FuelType.ron95:
        return _latestPrice!.ron95;

      case FuelType.ron97:
        return _latestPrice!.ron97;

      case FuelType.diesel:
        return _isEastMalaysia
            ? _latestPrice!.dieselEastMalaysia
            : _latestPrice!.diesel;

      default:
        return 0;
    }
  }

  double get _subtotal => _liters * _pricePerLiter;

  double get _discount {
    if (_selectedVoucher == null) {
      return 0;
    }

    if (_selectedVoucher!.discountType == 'fixed') {
      return _selectedVoucher!.discountValue;
    } else {
      return _subtotal *
          (_selectedVoucher!.discountValue / 100);
    }
  }

  double get _totalAmount => _subtotal - _discount;

  double get _maxLiters =>
      _selectedVehicle?.tankCapacity ?? 50;

  bool get _canProceed =>
      !_isLoading &&
          !_isProcessing &&
          (widget.initialVehicleId == null || _estimateApplied) &&
          _selectedVehicle != null &&
          _pumpNumber != null &&
          _selectedFuelType != null &&
          _pricePerLiter.isFinite &&
          _pricePerLiter > 0 &&
          _liters.isFinite &&
          _liters > 1 &&
          _liters <= _maxLiters;



  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _litersController.dispose();
    super.dispose();
  }

  // ============================================================
  // Data Loading
  // ============================================================

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        _showLoginRequired();

        setState(() => _isLoading = false);
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      // ========================================================
      // 1. Load cached fuel price
      // ========================================================

      final cachedPriceJson =
      prefs.getString('cached_fuel_price');

      FuelPrice? cachedPrice;

      if (cachedPriceJson != null) {
        try {
          final data = jsonDecode(cachedPriceJson);

          cachedPrice = FuelPrice.fromJson(data);

          setState(() {
            _latestPrice = cachedPrice;
          });
        } catch (_) {}
      }

      // ========================================================
      // 2. Get latest fuel price
      // ========================================================

      try {
        final latestPrice = await _fuelPriceService
            .getLatestFuelPrice()
            .timeout(
          const Duration(seconds: 5),
        );

        setState(() {
          _latestPrice = latestPrice;
        });

        await prefs.setString(
          'cached_fuel_price',
          jsonEncode(latestPrice.toJson()),
        );
      } catch (e) {
        if (_latestPrice == null) {
          setState(() {
            _latestPrice = FuelPrice(
              date: DateTime.now(),
              ron95: 2.095,
              ron97: 2.495,
              diesel: 1.895,
              dieselEastMalaysia: 1.895,
              ron95Budi: null,
              ron95Skps: null,
            );
          });
        }
      }

      // ========================================================
      // 3. Load vehicles + vouchers + points
      // ========================================================

      final results = await Future.wait([
        _vehicleService.getVehicles(),
        _paymentService.getAvailableUserVouchers(user.id),
        _paymentService.getUserPoints(user.id),
      ]);

      _vehicles = results[0] as List<Vehicle>;

      final userVouchers =
      results[1] as List<UserVoucher>;

      _availableVouchers = userVouchers
          .where((uv) => uv.isAvailable)
          .map((uv) => uv.voucher!)
          .where((reward) {
            final rewardBrand =
              (reward.stationBrand ?? '').toLowerCase().trim();

            final currentStationBrand =
              (widget.stationBrand ?? '').toLowerCase().trim();

            // No station brand means Universal
            if (rewardBrand.isEmpty) {
              return true;
            }

            // Only show rewards matching the current station brand
            return rewardBrand == _stationBrand;
          })
          .toList();

      _userPoints =
          (results[2] as Map<String, dynamic>)['available_points'] ?? 0;

      // ========================================================
      // 4. Cache vehicle data
      // ========================================================

      try {
        final vehiclesJson =
        _vehicles.map((v) => v.toJson()).toList();

        await prefs.setString(
          'cached_vehicles',
          jsonEncode(vehiclesJson),
        );
      } catch (_) {}

      if (!mounted) return;

      _selectVehicleAndApplyEstimate();

      await _updatePoints();

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error loading data: $e');

      setState(() => _isLoading = false);

      _showError(
        'Unable to load data. Please try again.',
      );
    }
  }

  void _selectVehicleAndApplyEstimate() {
    final applyingEstimate =
        widget.initialVehicleId != null &&
            !_estimateApplied;

    final requestedId = applyingEstimate
        ? widget.initialVehicleId
        : _selectedVehicle?.id;

    Vehicle? chosen;

    for (final vehicle in _vehicles) {
      if (vehicle.id == requestedId) {
        chosen = vehicle;
        break;
      }
    }

    if (applyingEstimate && chosen == null) {
      throw Exception(
        'The estimated vehicle is no longer available.',
      );
    }

    if (chosen == null && _vehicles.isNotEmpty) {
      chosen = _vehicles.firstWhere(
            (vehicle) => vehicle.isDefault,
        orElse: () => _vehicles.first,
      );
    }

    // ==========================================================
    // No vehicle
    // ==========================================================

    if (chosen == null) {
      _selectedVehicle = null;
      _selectedFuelType = null;
      _liters = 0;
      _litersController.clear();
      return;
    }

    final vehicleChanged =
        _selectedVehicle?.id != chosen.id;

    // ==========================================================
    // Apply refill estimate
    // ==========================================================

    if (applyingEstimate) {
      final litres = widget.initialLitres;
      final fuelName = widget.initialFuelType;
      final capacity = chosen.tankCapacity;

      FuelType? fuel;

      for (final item in FuelType.values) {
        if (item.label == fuelName) {
          fuel = item;
          break;
        }
      }

      if (litres == null ||
          !litres.isFinite ||
          litres <= 0 ||
          fuel == null) {
        throw Exception(
          'The refill estimate is invalid.',
        );
      }

      if (capacity == null ||
          !capacity.isFinite ||
          capacity <= 0 ||
          litres > capacity) {
        throw Exception(
          'Check the saved vehicle tank capacity before using this estimate.',
        );
      }

      _selectedVehicle = chosen;
      _selectedFuelType = fuel;
      _liters = litres;

      _litersController.text =
          litres.toStringAsFixed(2);

      _pumpNumber = null;
      _estimateApplied = true;

      WidgetsBinding.instance.addPostFrameCallback(
            (_) {
          if (!mounted) return;

          final estimatedPrice =
              widget.estimatedPricePerLitre;

          final actualPrice = _pricePerLiter;

          final validPrice =
              actualPrice.isFinite &&
                  actualPrice > 0;

          final changed =
              estimatedPrice != null &&
                  (actualPrice - estimatedPrice).abs() >
                      0.000001;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration:
              const Duration(seconds: 8),
              content: Text(
                !validPrice
                    ? 'Refill amount copied, but a valid payment price '
                    'is unavailable. Refresh before continuing.'
                    : changed
                    ? 'Refill amount copied. Payment uses a different '
                    'price from the estimate. Review the total '
                    'and select a pump before continuing.'
                    : 'Refill amount copied. Review the total '
                    'and select a pump before continuing.',
              ),
            ),
          );
        },
      );

      return;
    }

    // ==========================================================
    // Preserve user-entered details
    // ==========================================================

    _selectedVehicle = chosen;

    if (vehicleChanged) {
      _selectedFuelType =
          FuelType.fromString(chosen.fuelType);

      _liters = 0;

      _litersController.clear();
    }
  }

  // ============================================================
  // Error / Login
  // ============================================================

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please login first'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // ============================================================
  // Points
  // ============================================================

  Future<void> _updatePoints() async {
    if (_totalAmount > 0) {
      final points =
      await _paymentService.calculatePoints(
        _totalAmount,
      );

      if (!mounted) return;

      setState(() {
        _pointsEarned = points;
      });
    } else {
      if (!mounted) return;

      setState(() {
        _pointsEarned = 0;
      });
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFFE1F2FF),
        centerTitle: true,
        elevation: 0,

        title: const Text(
          'Fuel Purchase',
          style: TextStyle(
            color: Color(0xFF153B60),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1687E8),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadData,

        child: ListView(
          padding:
          const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            40,
          ),

          children: [
            _buildStationSection(),

            const SizedBox(height: 18),

            _buildVehicleSection(),

            const SizedBox(height: 18),

            _buildPumpSection(),

            const SizedBox(height: 18),

            _buildFuelTypeSection(),

            const SizedBox(height: 18),

            _buildLitersSection(),

            const SizedBox(height: 18),

            _buildVoucherSection(),

            const SizedBox(height: 18),

            _buildPriceSection(),

            const SizedBox(height: 25),

            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Station Section
  // ============================================================

  Widget _buildStationSection() {
    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFE4EBF2),
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Icon(
                Icons.local_gas_station_rounded,
                color: Color(0xFF1687E8),
                size: 20,
              ),

              const SizedBox(width: 8),

              const Text(
                'Station',
                style: TextStyle(
                  color: Color(0xFF153B60),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            widget.stationName,
            style: const TextStyle(
              color: Color(0xFF153B60),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          if (widget.stationAddress != null)
            Text(
              widget.stationAddress!,
              style: const TextStyle(
                color: Color(0xFF718096),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // Vehicle Section
  // ============================================================

  Widget _buildVehicleSection() {
    // ==========================================================
    // No vehicles
    // ==========================================================

    if (_vehicles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(17),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: const Color(0xFFE4EBF2),
          ),

          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          children: [
            const Text(
              'No vehicles added yet',
              style: TextStyle(
                color: Color(0xFF718096),
              ),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () async {
                final result =
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const VehicleFormScreen(),
                  ),
                );

                if (!mounted) return;

                if (result == true) {
                  await _loadData();
                }
              },

              child: const Text(
                'Add Vehicle',
                style: TextStyle(
                  color: Color(0xFF1687E8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // Vehicle exists
    // ==========================================================

    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFE4EBF2),
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_car_rounded,
                color: Color(0xFF1687E8),
                size: 20,
              ),

              const SizedBox(width: 8),

              const Text(
                'Select Vehicle',
                style: TextStyle(
                  color: Color(0xFF153B60),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<Vehicle>(
            value: _selectedVehicle,
            isExpanded: true,

            decoration: InputDecoration(
              hintText: 'Select your vehicle',

              filled: true,
              fillColor: const Color(0xFFF8FAFC),

              enabledBorder:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(13),

                borderSide: const BorderSide(
                  color: Color(0xFFDCE5ED),
                ),
              ),

              focusedBorder:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(13),

                borderSide: const BorderSide(
                  color: Color(0xFF1687E8),
                  width: 2,
                ),
              ),
            ),

            items: _vehicles.map(
                  (vehicle) {
                return DropdownMenuItem(
                  value: vehicle,

                  child: Text(
                    '${vehicle.vehicleName} '
                        '(${vehicle.plateNumber})'
                        '${vehicle.tankCapacity != null ? " - ${vehicle.tankCapacity!.toStringAsFixed(0)}L" : ""}',

                    style: const TextStyle(
                      color: Color(0xFF153B60),
                    ),
                  ),
                );
              },
            ).toList(),

            onChanged: (value) {
              setState(() {
                _selectedVehicle = value;

                if (value != null) {
                  final fuelTypeMap = {
                    'RON95': FuelType.ron95,
                    'RON97': FuelType.ron97,
                    'Diesel': FuelType.diesel,
                  };

                  _selectedFuelType =
                      fuelTypeMap[value.fuelType] ??
                          FuelType.ron95;
                }

                _liters = 0;
                _litersController.clear();
              });

              _updatePoints();
            },
          ),

          if (_selectedVehicle?.tankCapacity != null)
            Padding(
              padding:
              const EdgeInsets.only(top: 8),

              child: Text(
                'Tank capacity: '
                    '${_selectedVehicle!.tankCapacity!.toStringAsFixed(0)}L',

                style: const TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // Pump Section
  // ============================================================

  Widget _buildPumpSection() {
    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFE4EBF2),
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Icon(
                Icons.pin_outlined,
                color: Color(0xFF1687E8),
                size: 20,
              ),

              const SizedBox(width: 8),

              const Text(
                'Pump Number',
                style: TextStyle(
                  color: Color(0xFF153B60),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (_pumpNumber == null) ...[
                const SizedBox(width: 8),

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius:
                    BorderRadius.circular(8),
                  ),

                  child: Text(
                    'Please select',

                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 6,
            runSpacing: 6,

            children: List.generate(
              10,
                  (index) {
                final number = index + 1;

                final isSelected =
                    _pumpNumber == number;

                return ChoiceChip(
                  label: Text('$number'),

                  selected: isSelected,

                  onSelected: (selected) {
                    setState(() {
                      _pumpNumber =
                      selected ? number : null;
                    });
                  },

                  selectedColor:
                  const Color(0xFF1687E8),

                  backgroundColor:
                  const Color(0xFFF8FAFC),

                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF153B60),

                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(10),

                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF1687E8)
                          : const Color(0xFFDCE5ED),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          if (_pumpNumber != null)
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),

                const SizedBox(width: 6),

                Text(
                  'Pump $_pumpNumber selected',

                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.red,
                  size: 16,
                ),

                const SizedBox(width: 6),

                Text(
                  'Please select a pump number to continue',

                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // Fuel Type Section
  // ============================================================

  Widget _buildFuelTypeSection() {
    // ==========================================================
    // IMPORTANT:
    // Do NOT show "Please select a vehicle first"
    // ==========================================================

    if (_selectedVehicle == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFE4EBF2),
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Icon(
                Icons.local_gas_station_rounded,
                color: Color(0xFF1687E8),
                size: 20,
              ),

              const SizedBox(width: 8),

              const Text(
                'Fuel Type',
                style: TextStyle(
                  color: Color(0xFF153B60),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            padding:
            const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),

            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius:
              BorderRadius.circular(12),

              border: Border.all(
                color: const Color(0xFFCCDFFF),
              ),
            ),

            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 20,
                ),

                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    Text(
                      '${_selectedVehicle!.fuelType}',

                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF153B60),
                      ),
                    ),

                    Text(
                      'RM${_pricePerLiter.toStringAsFixed(2)} per liter',

                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Based on your vehicle\'s fuel type',

            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Liters Section
  // ============================================================
  Widget _buildLitersSection() {
    final bool hasError =
        _liters > _maxLiters ||
            (_liters < 1 && _litersController.text.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: hasError
              ? Colors.red.shade300
              : const Color(0xFFE4EBF2),
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Icon(
                Icons.water_drop_outlined,
                color: Color(0xFF1687E8),
                size: 20,
              ),

              const SizedBox(width: 8),

              const Text(
                'Quantity (L)',
                style: TextStyle(
                  color: Color(0xFF153B60),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          TextField(
            controller: _litersController,

            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),

            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d*\.?\d{0,2}$'),
              ),

              LengthLimitingTextInputFormatter(5),
            ],

            decoration: InputDecoration(
              hintText: 'Enter liters',

              suffixText: 'L',

              filled: true,
              fillColor: const Color(0xFFF8FAFC),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),

                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red
                      : const Color(0xFFDCE5ED),
                ),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),

                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red
                      : const Color(0xFF1687E8),

                  width: 2,
                ),
              ),

              errorText:
              _liters > _maxLiters
                  ? 'Maximum capacity is '
                  '${_maxLiters.toStringAsFixed(0)}L'
                  : _liters < 1 &&
                  _litersController.text.isNotEmpty
                  ? 'Minimum amount is 1L'
                  : null,

              errorStyle: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),

            onChanged: (value) {
              final parsed = double.tryParse(value);

              setState(() {
                if (parsed != null) {
                  _liters = parsed;
                } else {
                  _liters = 0;
                }
              });

              _updatePoints();
            },
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                'Min: 1 L',

                style: TextStyle(
                  fontSize: 12,

                  color:
                  _liters >= 1 &&
                      _liters <= _maxLiters
                      ? const Color(0xFF718096)
                      : Colors.red,
                ),
              ),

              Text(
                'Max: '
                    '${_maxLiters.toStringAsFixed(0)} L',

                style: TextStyle(
                  fontSize: 12,

                  color: _liters > _maxLiters
                      ? Colors.red
                      : const Color(0xFF718096),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Voucher Section
  // ============================================================

  Widget _buildVoucherSection() {
    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFE4EBF2),
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_offer_rounded,
                    color: Color(0xFF1687E8),
                    size: 20,
                  ),

                  const SizedBox(width: 8),

                  const Text(
                    'Apply Voucher',
                    style: TextStyle(
                      color: Color(0xFF153B60),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),

                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius:
                  BorderRadius.circular(12),
                ),

                child: Text(
                  '$_userPoints pts',

                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ====================================================
          // No vouchers
          // ====================================================

          if (_availableVouchers.isEmpty)
            Container(
              padding:
              const EdgeInsets.symmetric(
                vertical: 12,
              ),

              alignment: Alignment.center,

              child: const Text(
                'No vouchers available.\n'
                    'Redeem some with your points!',

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 13,
                ),
              ),
            )

          // ====================================================
          // Vouchers available
          // ====================================================

          else
            DropdownButtonFormField<Voucher?>(
              value: _selectedVoucher,

              isExpanded: true,

              hint: const Text(
                'Select a voucher to apply',

                style: TextStyle(
                  color: Color(0xFF718096),
                ),
              ),

              decoration: InputDecoration(
                filled: true,

                fillColor:
                const Color(0xFFF8FAFC),

                enabledBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(13),

                  borderSide:
                  const BorderSide(
                    color: Color(0xFFDCE5ED),
                  ),
                ),

                focusedBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(13),

                  borderSide:
                  const BorderSide(
                    color: Color(0xFF1687E8),
                    width: 2,
                  ),
                ),
              ),

              items: [
                const DropdownMenuItem<Voucher?>(
                  value: null,

                  child: Text(
                    'No voucher',

                    style: TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 14,
                    ),
                  ),
                ),

                ..._availableVouchers.map(
                      (voucher) {
                    return DropdownMenuItem<
                        Voucher?>(
                      value: voucher,

                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              voucher.name,

                              style:
                              const TextStyle(
                                color:
                                Color(0xFF153B60),
                                fontSize: 14,
                              ),

                              overflow:
                              TextOverflow.ellipsis,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),

                            decoration:
                            BoxDecoration(
                              color:
                              const Color(
                                0xFFE8F5E9,
                              ),

                              borderRadius:
                              BorderRadius
                                  .circular(8),
                            ),

                            child: Text(
                              voucher.discountType ==
                                  'fixed'
                                  ? 'RM${voucher.discountValue.toStringAsFixed(2)} off'
                                  : '${voucher.discountValue.toInt()}% off',

                              style:
                              const TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ).toList(),
              ],

              onChanged: (value) {
                setState(() {
                  _selectedVoucher = value;
                });

                _updatePoints();
              },
            ),

          if (_selectedVoucher != null)
            Padding(
              padding:
              const EdgeInsets.only(top: 8),

              child: Text(
                _selectedVoucher!.description ??
                    'No description available',

                style: const TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // Price Section
  // ============================================================

  Widget _buildPriceSection() {
    if (_selectedFuelType == null) {
      return Container(
        padding: const EdgeInsets.all(17),

        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius:
          BorderRadius.circular(18),

          border: Border.all(
            color: const Color(0xFFE4EBF2),
          ),
        ),

        child: const Center(
          child: Text(
            'Please select fuel type first',

            style: TextStyle(
              color: Color(0xFF718096),
            ),
          ),
        ),
      );
    }

    if (_liters <= 0) {
      return Container(
        padding: const EdgeInsets.all(17),

        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius:
          BorderRadius.circular(18),

          border: Border.all(
            color: const Color(0xFFE4EBF2),
          ),
        ),

        child: const Center(
          child: Text(
            'Please enter quantity',

            style: TextStyle(
              color: Color(0xFF718096),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFDDEEFF),
            Color(0xFFF0F7FF),
          ],
        ),

        borderRadius:
        BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFCCDFFF),
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          const Text(
            'Price Summary',

            style: TextStyle(
              color: Color(0xFF153B60),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

            children: [
              Text(
                '${_liters.toStringAsFixed(1)} L × '
                    'RM${_pricePerLiter.toStringAsFixed(2)}',

                style: const TextStyle(
                  color: Color(0xFF153B60),
                ),
              ),

              Text(
                'RM${_subtotal.toStringAsFixed(2)}',

                style: const TextStyle(
                  color: Color(0xFF153B60),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          if (_discount > 0) ...[
            const Divider(
              color: Color(0xFFCCDFFF),
            ),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

              children: [
                Text(
                  'Discount '
                      '(${_selectedVoucher?.name ?? ''})',

                  style: const TextStyle(
                    color: Colors.green,
                  ),
                ),

                Text(
                  '-RM${_discount.toStringAsFixed(2)}',

                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          const Divider(
            color: Color(0xFFCCDFFF),
          ),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

            children: [
              const Text(
                'Total',

                style: TextStyle(
                  color: Color(0xFF153B60),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                'RM${_totalAmount.toStringAsFixed(2)}',

                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1687E8),
                ),
              ),
            ],
          ),

          if (_pointsEarned > 0) ...[
            const SizedBox(height: 10),

            Container(
              padding:
              const EdgeInsets.all(10),

              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius:
                BorderRadius.circular(12),

                border: Border.all(
                  color: const Color(0xFFFFE0B2),
                ),
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Colors.orange,
                    size: 18,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    'You will earn '
                        '$_pointsEarned points from this purchase',

                    style: const TextStyle(
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // Submit Button
  // ============================================================

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,

      child: ElevatedButton(
        onPressed:
        _isProcessing || !_canProceed
            ? null
            : _handleProceed,

        style: ElevatedButton.styleFrom(
          padding:
          const EdgeInsets.symmetric(
            vertical: 16,
          ),

          backgroundColor:
          const Color(0xFF1687E8),

          foregroundColor: Colors.white,

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(14),
          ),
        ),

        child: _isProcessing
            ? const SizedBox(
          height: 22,
          width: 22,

          child:
          CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        )
            : const Text(
          'Proceed to Payment',

          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Navigation / Proceed
  // ============================================================

  Future<void> _handleProceed() async {
    if (!_canProceed) return;

    final supabase =
        Supabase.instance.client;

    final user =
        supabase.auth.currentUser;

    // ==========================================================
    // Login validation
    // ==========================================================

    if (user == null) {
      _showLoginRequired();
      return;
    }

    // ==========================================================
    // Vehicle validation
    //
    // IMPORTANT:
    // This is BEFORE pump validation.
    // So if no vehicle exists, user sees:
    // "Please select a vehicle."
    // ==========================================================

    final selectedVehicle =
        _selectedVehicle;

    if (selectedVehicle == null) {
      _showError(
        'Please select a vehicle.',
      );
      return;
    }

    // ==========================================================
    // Pump validation
    // ==========================================================

    if (_pumpNumber == null) {
      _showError(
        'Please select a pump number',
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // ========================================================
      // Prepare vehicle for payment
      // ========================================================

      final serverVehicleId =
      await _vehicleService
          .prepareVehicleForPayment(
        selectedVehicle.id,
      );

      if (!mounted) return;

      // ========================================================
      // Payment Data
      // ========================================================

      final paymentData = {
        'userId': user.id,

        'placeId': widget.placeId,

        'stationName':
        widget.stationName,

        'stationAddress':
        widget.stationAddress,

        'vehicleId':
        serverVehicleId,

        // Vehicle information
        'vehicleName':
        selectedVehicle.vehicleName,

        'vehiclePlate':
        selectedVehicle.plateNumber,

        'pumpNumber':
        _pumpNumber!,

        'fuelType':
        _selectedFuelType!.label,

        'quantityLiters':
        _liters,

        'pricePerLiter':
        _pricePerLiter,

        'voucherId':
        _selectedVoucher?.id,

        'paymentMethod':
        '',

        'totalAmount':
        _totalAmount,
      };

      // ========================================================
      // Go to Payment Method
      // ========================================================

      if (mounted) {
        Navigator.push(
          context,

          MaterialPageRoute(
            builder: (context) =>
                PaymentMethodPage(
                  paymentData:
                  paymentData,
                ),
          ),
        );
      }
    } catch (e) {
      _showError(
        'Unable to proceed: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}