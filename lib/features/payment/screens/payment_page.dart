// features/payment/screens/payment_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../vehicle/models/vehicle_model.dart';
import '../../vehicle/services/vehicle_service.dart';
import '../../fuel_price/services/fuel_price_service.dart';
import '../../fuel_price/models/fuel_price_model.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import 'payment_method_page.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PaymentPage extends StatefulWidget {
  final String placeId;
  final String stationName;
  final String? stationAddress;

  const PaymentPage({
    super.key,
    required this.placeId,
    required this.stationName,
    this.stationAddress,
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

  final TextEditingController _litersController = TextEditingController();

  // ============================================================
  // Computed Properties
  // ============================================================

  double get _pricePerLiter {
    if (_selectedFuelType == null || _latestPrice == null) return 0;

    switch (_selectedFuelType) {
      case FuelType.ron95:
        return _latestPrice!.ron95;
      case FuelType.ron97:
        return _latestPrice!.ron97;
      case FuelType.diesel:
        return _latestPrice!.diesel;
      default:
        return 0;
    }
  }

  double get _subtotal => _liters * _pricePerLiter;

  double get _discount {
    if (_selectedVoucher == null) return 0;

    if (_selectedVoucher!.discountType == 'fixed') {
      return _selectedVoucher!.discountValue;
    } else {
      return _subtotal * (_selectedVoucher!.discountValue / 100);
    }
  }

  double get _totalAmount => _subtotal - _discount;

  double get _maxLiters => _selectedVehicle?.tankCapacity ?? 50;

  bool get _canProceed =>
      _selectedVehicle != null &&
          _pumpNumber != null &&
          _selectedFuelType != null &&
          _liters > 0 &&
          _liters <= _maxLiters;

  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        _showLoginRequired();
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      final cachedPriceJson = prefs.getString('cached_fuel_price');
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

      try {
        final latestPrice = await _fuelPriceService
            .getLatestFuelPrice()
            .timeout(const Duration(seconds: 5));

        setState(() {
          _latestPrice = latestPrice;
        });
        await prefs.setString('cached_fuel_price', jsonEncode(latestPrice.toJson()));
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

      try {
        final vehicles = await _vehicleService
            .getVehicles()
            .timeout(const Duration(seconds: 5));

        setState(() {
          _vehicles = vehicles;
        });

        final vehiclesJson = vehicles.map((v) => v.toJson()).toList();
        await prefs.setString('cached_vehicles', jsonEncode(vehiclesJson));
      } catch (e) {
        if (_vehicles.isEmpty) {
          setState(() {
            _vehicles = [];
          });
        }
      }

      // Load data in parallel
      final results = await Future.wait([
        _vehicleService.getVehicles(),
        _fuelPriceService.getLatestFuelPrice(),
        _paymentService.getAvailableVouchers(),
        _paymentService.getUserPoints(user.id),
      ]);

      _vehicles = results[0] as List<Vehicle>;
      _latestPrice = results[1] as FuelPrice;
      _availableVouchers = results[2] as List<Voucher>;
      _userPoints = (results[3] as Map<String, dynamic>)['available_points'] ?? 0;

      // Auto-select default vehicle
      final defaultVehicle = _vehicles.firstWhere(
            (v) => v.isDefault,
        orElse: () => _vehicles.isNotEmpty ? _vehicles.first : throw Exception('No vehicle'),
      );
      if (defaultVehicle != null) {
        _selectedVehicle = defaultVehicle;
        _liters = _selectedVehicle!.tankCapacity != null
            ? _selectedVehicle!.tankCapacity! * 0.5
            : 20.0;
      }

      await _updatePoints();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Unable to load data.');
    }
  }

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

  Future<void> _updatePoints() async {
    if (_totalAmount > 0) {
      final points = await _paymentService.calculatePoints(_totalAmount);
      setState(() {
        _pointsEarned = points;
      });
    } else {
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
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
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
            _buildPriceSection(),
            const SizedBox(height: 18),
            _buildVoucherSection(),
            const SizedBox(height: 25),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UI Components
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
        crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildVehicleSection() {
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
              onPressed: () {
                // TODO: Navigate to add vehicle
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
            initialValue: _selectedVehicle,
            decoration: InputDecoration(
              hintText: 'Select your vehicle',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFFDCE5ED),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFF1687E8),
                  width: 2,
                ),
              ),
            ),
            items: _vehicles.map((vehicle) {
              return DropdownMenuItem(
                value: vehicle,
                child: Text(
                  '${vehicle.vehicleName} (${vehicle.plateNumber}) - ${vehicle.tankCapacity?.toStringAsFixed(0)}L',
                  style: const TextStyle(
                    color: Color(0xFF153B60),
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedVehicle = value;
                if (value?.tankCapacity != null) {
                  _liters = value!.tankCapacity! * 0.5;
                }
              });
            },
          ),
          if (_selectedVehicle?.tankCapacity != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Tank capacity: ${_selectedVehicle!.tankCapacity!.toStringAsFixed(0)}L',
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(10, (index) {
              final number = index + 1;
              final isSelected = _pumpNumber == number;
              return ChoiceChip(
                label: Text('$number'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _pumpNumber = selected ? number : null;
                  });
                },
                selectedColor: const Color(0xFF1687E8),
                backgroundColor: const Color(0xFFF8FAFC),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF153B60),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF1687E8)
                        : const Color(0xFFDCE5ED),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelTypeSection() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 10),
          if (_latestPrice != null) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FuelType.values.map((type) {
                double price = 0;
                switch (type) {
                  case FuelType.ron95:
                    price = _latestPrice!.ron95;
                    break;
                  case FuelType.ron97:
                    price = _latestPrice!.ron97;
                    break;
                  case FuelType.diesel:
                    price = _latestPrice!.diesel;
                    break;
                }
                final isSelected = _selectedFuelType == type;
                return ChoiceChip(
                  label: Text(
                    '${type.label} (RM${price.toStringAsFixed(3)})',
                    style: const TextStyle(fontSize: 13),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFuelType = selected ? type : null;
                    });
                    _updatePoints();
                  },
                  selectedColor: const Color(0xFF1687E8),
                  backgroundColor: const Color(0xFFF8FAFC),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF153B60),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF1687E8)
                          : const Color(0xFFDCE5ED),
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            const Text(
              'Loading prices...',
              style: TextStyle(
                color: Color(0xFF718096),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLitersSection() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EBF2)),
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
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d*\.?\d{0,2}'),
              ),
            ],
            decoration: InputDecoration(
              hintText: 'Enter liters',  // ← 只有提示，没有默认值
              suffixText: 'L',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFFDCE5ED),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFF1687E8),
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              final parsed = double.tryParse(value);
              if (parsed != null && parsed > 0) {
                setState(() {
                  _liters = parsed.clamp(1, _maxLiters);
                });
                _updatePoints();
              } else {
                setState(() {
                  _liters = 0;
                });
                _updatePoints();
              }
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: 1 L',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                ),
              ),
              Text(
                'Max: ${_maxLiters.toStringAsFixed(0)} L',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    if (_selectedFuelType == null) {
      return Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
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

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFDDEEFF),
            Color(0xFFF0F7FF),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFCCDFFF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_liters.toStringAsFixed(1)} L × RM${_pricePerLiter.toStringAsFixed(3)}',
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discount (${_selectedVoucher?.name ?? ''})',
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
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
                  'You will earn $_pointsEarned points from this purchase',
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
      ),
    );
  }

  Widget _buildVoucherSection() {
    if (_availableVouchers.isEmpty) {

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
        child: const Center(
          child: Text(
            'No vouchers available',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
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
          DropdownButtonFormField<Voucher>(
            initialValue: _selectedVoucher,
            decoration: InputDecoration(
              hintText: 'Select voucher',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFFDCE5ED),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFF1687E8),
                  width: 2,
                ),
              ),
            ),
            items: _availableVouchers.map((voucher) {
              final canAfford = _userPoints >= voucher.pointsRequired;
              return DropdownMenuItem(
                value: voucher,
                enabled: canAfford,
                child: Row(
                  children: [
                    Text(
                      voucher.name,
                      style: TextStyle(
                        color: canAfford
                            ? const Color(0xFF153B60)
                            : const Color(0xFF718096),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${voucher.pointsRequired} pts)',
                      style: TextStyle(
                        color: canAfford ? Colors.green : const Color(0xFF718096),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedVoucher = value;
              });
              _updatePoints();
            },
          ),
          if (_selectedVoucher != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _selectedVoucher!.description ?? '',
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing || !_canProceed ? null : _handleProceed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFF1687E8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isProcessing
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
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
  // Navigation
  // ============================================================

  void _handleProceed() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      _showLoginRequired();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final paymentData = {
        'userId': user.id,
        'placeId': widget.placeId,
        'stationName': widget.stationName,
        'stationAddress': widget.stationAddress,
        'vehicleId': _selectedVehicle?.id,
        'pumpNumber': _pumpNumber!,
        'fuelType': _selectedFuelType!.label,
        'quantityLiters': _liters,
        'pricePerLiter': _pricePerLiter,
        'voucherId': _selectedVoucher?.id,
        'paymentMethod': '',
        'totalAmount': _totalAmount,
      };

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentMethodPage(
              paymentData: paymentData,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Unable to proceed: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}