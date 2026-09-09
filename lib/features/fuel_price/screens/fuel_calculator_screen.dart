import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../vehicle/models/vehicle_model.dart';
import '../../vehicle/services/vehicle_service.dart';
import '../../vehicle/screens/vehicle_form_screen.dart';
import '../../fuel_station/models/fuel_station_model.dart';
import '../../fuel_station/screens/station_list_screen.dart';
import '../../payment/screens/payment_page.dart';
import '../models/fuel_price_model.dart';
import '../services/fuel_price_service.dart';

class FuelCalculatorScreen extends StatefulWidget {
  const FuelCalculatorScreen({super.key});

  @override
  State<FuelCalculatorScreen> createState() =>
      _FuelCalculatorScreenState();
}

class _FuelCalculatorScreenState extends State<FuelCalculatorScreen> {
  static const _blue = Color(0xFF1687E8);
  static const _dark = Color(0xFF153B60);
  static const _muted = Color(0xFF718096);
  static const _background = Color(0xFFF5F7FA);
  static const _border = Color(0xFFE2E8F0);

  final _formKey = GlobalKey<FormState>();
  final _vehicleService = VehicleService();
  final _priceService = FuelPriceService();

  final _distanceController = TextEditingController(text: '200');
  final _efficiencyController = TextEditingController();

  final _decimal = NumberFormat('#,##0.00', 'en_US');
  final _distanceFormat = NumberFormat('#,##0.0', 'en_US');
  final _compact = NumberFormat('#,##0.##', 'en_US');

  List<Vehicle> _vehicles = [];
  String? _selectedVehicleId;
  FuelPrice? _prices;
  _TripEstimate? _result;

  bool _loading = true;
  bool _openingPayment = false;
  bool _editingVehicle = false;
  bool _eastMalaysia = false;
  bool _useBudi95 = false;
  bool _returnTrip = false;
  bool _addAllowance = false;

  double _tankPercent = 25;
  String? _error;

  static const double _minimumRefillLitres = 1.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _efficiencyController.dispose();
    super.dispose();
  }

  Vehicle? get _selectedVehicle {
    for (final vehicle in _vehicles) {
      if (vehicle.id == _selectedVehicleId) {
        return vehicle;
      }
    }
    return null;
  }

  String get _fuelType => _selectedVehicle?.fuelType ?? '';

  bool get _supportedFuel =>
      ['RON95', 'RON97', 'Diesel'].contains(_fuelType);

  bool get _validCapacity {
    final capacity = _selectedVehicle?.tankCapacity;
    return capacity != null &&
        capacity.isFinite &&
        capacity >= 5 &&
        capacity <= 200;
  }

  bool get _budiAvailable {
    final price = _prices?.ron95Budi;
    return price != null && price.isFinite && price > 0;
  }

  double get _pricePerLitre {
    final prices = _prices;
    if (prices == null) return 0;

    switch (_fuelType) {
      case 'RON95':
        return _useBudi95
            ? (prices.ron95Budi ?? 0)
            : prices.ron95;
      case 'RON97':
        return prices.ron97;
      case 'Diesel':
        return prices.dieselForRegion(_eastMalaysia);
      default:
        return 0;
    }
  }

  bool get _alternativePrice =>
      (_fuelType == 'RON95' && _useBudi95) ||
          (_fuelType == 'Diesel' && _eastMalaysia);

  String _money(double value) => 'RM ${_decimal.format(value)}';
  String _litres(double value) => '${_decimal.format(value)} L';
  String _distance(double value) =>
      '${_distanceFormat.format(value)} km';

  void _invalidate() {
    if (_result == null) return;
    setState(() => _result = null);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final data = await Future.wait<Object>([
        _vehicleService.getVehicles(),
        _priceService.getLatestFuelPrice(),
      ]);

      if (!mounted) return;

      final vehicles = data[0] as List<Vehicle>;
      final prices = data[1] as FuelPrice;

      Vehicle? selected;

      for (final vehicle in vehicles) {
        if (vehicle.id == _selectedVehicleId) {
          selected = vehicle;
          break;
        }
      }

      if (selected == null && vehicles.isNotEmpty) {
        selected = vehicles.firstWhere(
              (vehicle) => vehicle.isDefault,
          orElse: () => vehicles.first,
        );
      }

      setState(() {
        _vehicles = vehicles;
        _prices = prices;
        _useBudi95 = false;

        if (selected != null) {
          _applyVehicle(selected);
        } else {
          _selectedVehicleId = null;
          _efficiencyController.clear();
        }

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load vehicles or prices. '
            'Check your connection and sign-in status.';
      });
    }
  }

  void _applyVehicle(Vehicle vehicle) {
    _selectedVehicleId = vehicle.id;
    _efficiencyController.text =
        vehicle.fuelEfficiency?.toString() ?? '';
    _useBudi95 = false;
    _result = null;
  }

  Future<void> _editVehicle() async {
    if (_editingVehicle) return;
    setState(() => _editingVehicle = true);

    try {
      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => VehicleFormScreen(
            vehicle: _selectedVehicle,
          ),
        ),
      );

      if (!mounted) return;
      if (changed == true) await _loadData();
    } finally {
      if (mounted) {
        setState(() => _editingVehicle = false);
      }
    }
  }

  String? _validateNumber(
      String? value, {
        required double minimum,
        required double maximum,
        required String unit,
      }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'Required';

    if (!RegExp(r'^[0-9]+(?:\.[0-9]{1,2})?$').hasMatch(text)) {
      return 'Use up to 2 decimal places.';
    }

    final number = double.tryParse(text);

    if (number == null ||
        !number.isFinite ||
        number < minimum ||
        number > maximum) {
      return 'Enter ${_compact.format(minimum)}'
          '–${_compact.format(maximum)} $unit.';
    }

    return null;
  }

  void _calculate() {
    final vehicle = _selectedVehicle;

    if (vehicle == null || !_validCapacity || !_supportedFuel) {
      _showMessage('Complete your saved vehicle details first.');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      _invalidate();
      return;
    }

    final price = _pricePerLitre;

    if (!price.isFinite || price <= 0) {
      _invalidate();
      _showMessage('Fuel price unavailable. Please refresh.');
      return;
    }

    FocusScope.of(context).unfocus();

    final efficiency =
    double.parse(_efficiencyController.text.trim());
    final oneWay =
    double.parse(_distanceController.text.trim());
    final capacity = vehicle.tankCapacity!;

    final tripDistance = oneWay * (_returnTrip ? 2 : 1);
    final existingFuel = capacity * _tankPercent / 100;
    final freeSpace = math.max(0.0, capacity - existingFuel);

    final baseFuel = tripDistance / efficiency;
    final extraFuel = _addAllowance ? baseFuel * 0.10 : 0.0;
    final plannedFuel = baseFuel + extraFuel;

    final additionalFuel = math.max(
      0.0,
      plannedFuel - existingFuel,
    );

    final rawRefill = math.min(additionalFuel, freeSpace);

    // Round once. Use this same quantity for display, cost and payment.
    final roundedRefill =
    double.parse(rawRefill.toStringAsFixed(2));

    // Never exceed the estimated free space or saved tank capacity.
    final maximumRefill =
        (math.min(freeSpace, capacity) * 100).floor() / 100.0;

    final refillNow = math.min(roundedRefill, maximumRefill);

    // Do not mistake a rounding difference for a required fuel stop.
    final refillLater = math.max(
      0.0,
      additionalFuel - freeSpace,
    );

    String? notice;

    if (refillLater > 0.001) {
      notice = 'Plan refuelling stops: about '
          '${_litres(refillLater)} more is needed during the trip.';
    } else if (additionalFuel <= 0) {
      notice = 'Your estimated fuel is enough for this trip.';
    } else if (refillNow <= 0) {
      notice = 'The estimated top-up is too small for payment.';
    }

    setState(() {
      _result = _TripEstimate(
        vehicleId: vehicle.id,
        fuelType: vehicle.fuelType,
        refillLitres: refillNow,
        pricePerLitre: price,
        cost: refillNow * price,
        tripDistance: tripDistance,
        plannedFuel: plannedFuel,
        notice: notice,
        alternativePrice: _alternativePrice,
        details: [
          MapEntry('One-way distance', _distance(oneWay)),
          MapEntry('Return trip', _returnTrip ? 'Yes' : 'No'),
          MapEntry(
            'Efficiency used',
            '${_decimal.format(efficiency)} km/L',
          ),
          MapEntry('Price per litre', '${_money(price)} / L'),
          MapEntry('Trip consumption', _litres(baseFuel)),
          MapEntry('Allowance', _addAllowance ? '10%' : '0%'),
          MapEntry('Extra planning fuel', _litres(extraFuel)),
          MapEntry('Trip fuel budget', _money(plannedFuel * price)),
          MapEntry('Fuel already in tank', _litres(existingFuel)),
          MapEntry('Available tank space', _litres(freeSpace)),
          MapEntry('Additional fuel needed', _litres(additionalFuel)),
          if (refillLater > 0.001)
            MapEntry('Fuel needed en route', _litres(refillLater)),
        ],
      );
    });
  }

  Future<void> _useRefillAmount(_TripEstimate estimate) async {
    if (_openingPayment ||
        !estimate.refillLitres.isFinite ||
        estimate.refillLitres < _minimumRefillLitres) {
      return;
    }

    setState(() => _openingPayment = true);

    try {
      final station = await Navigator.push<FuelStation>(
        context,
        MaterialPageRoute(
          builder: (_) => const StationListScreen(
            selectionMode: true,
          ),
        ),
      );

      if (!mounted || station == null) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            placeId: station.placeId,
            stationName: station.stationName,
            stationAddress: station.stationAddress,
            initialVehicleId: estimate.vehicleId,
            initialFuelType: estimate.fuelType,
            initialLitres: estimate.refillLitres,
            estimatedPricePerLitre: estimate.pricePerLitre,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        _showMessage('Could not open payment. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _openingPayment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE1F2FF),
        centerTitle: true,
        title: const Text(
          'Fuel Estimator',
          style: TextStyle(
            color: _dark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading || _openingPayment || _editingVehicle
                ? null
                : _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadData,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        children: [
          _buildVehicleCard(),
          if (_selectedVehicle != null) ...[
            const SizedBox(height: 14),
            _buildTripCard(),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openingPayment ||
                  !_validCapacity ||
                  !_supportedFuel
                  ? null
                  : _calculate,
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calculate estimate'),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    final vehicle = _selectedVehicle;

    if (vehicle == null) {
      return _card(
        title: 'Your vehicle',
        children: [
          const Text('Add a vehicle to estimate your trip fuel.'),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _editingVehicle ? null : _editVehicle,
            icon: const Icon(Icons.add),
            label: const Text('Add vehicle'),
          ),
        ],
      );
    }

    final capacity = vehicle.tankCapacity;
    final price = _pricePerLitre;
    final validPrice = price.isFinite && price > 0;

    return _card(
      title: 'Your vehicle',
      action: TextButton(
        onPressed: _openingPayment || _editingVehicle
            ? null
            : _editVehicle,
        child: const Text('Edit details'),
      ),
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedVehicleId),
          initialValue: _selectedVehicleId,
          isExpanded: true,
          decoration: _decoration('Vehicle'),
          items: _vehicles.map((item) {
            return DropdownMenuItem(
              value: item.id,
              child: Text(
                '${item.vehicleName} · ${item.plateNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (id) {
            if (id == null) return;

            final selected = _vehicles.firstWhere(
                  (item) => item.id == id,
            );

            setState(() => _applyVehicle(selected));
          },
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F7FC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: _muted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${vehicle.fuelType}  ·  '
                      '${capacity != null && capacity.isFinite ? _litres(capacity) : 'Tank not set'}',
                  style: const TextStyle(
                    color: _dark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!_validCapacity || !_supportedFuel) ...[
          const SizedBox(height: 8),
          const Text(
            'Update fuel type and tank capacity in vehicle details.',
            style: TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        _numberField(
          controller: _efficiencyController,
          label: 'Fuel efficiency',
          unit: 'km/L',
          minimum: 1,
          maximum: 50,
        ),
        const SizedBox(height: 6),
        const Text(
          'Adjustable for this estimate only.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
        const Divider(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _useBudi95 && _fuelType == 'RON95'
                    ? 'BUDI95 price'
                    : '$_fuelType price',
                style: const TextStyle(color: _muted),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              validPrice ? '${_money(price)} / L' : 'Unavailable',
              style: const TextStyle(
                color: _dark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Updated ${DateFormat('d MMM yyyy').format(_prices!.date)}',
          style: const TextStyle(color: _muted, fontSize: 11),
        ),
        if (_fuelType == 'Diesel') ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<bool>(
            initialValue: _eastMalaysia,
            decoration: _decoration('Diesel region'),
            items: const [
              DropdownMenuItem(
                value: false,
                child: Text('Peninsular Malaysia'),
              ),
              DropdownMenuItem(
                value: true,
                child: Text('East Malaysia'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _eastMalaysia = value;
                _result = null;
              });
            },
          ),
        ],
        if (_fuelType == 'RON95' && _budiAvailable)
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Use BUDI95',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: const Text(
              'Eligible purchases only',
              style: TextStyle(fontSize: 11),
            ),
            value: _useBudi95,
            onChanged: (value) {
              setState(() {
                _useBudi95 = value;
                _result = null;
              });
            },
          ),
        if (_alternativePrice) ...[
          const SizedBox(height: 6),
          const Text(
            'Payment may use a different price.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildTripCard() {
    return _card(
      title: 'Your trip',
      children: [
        _numberField(
          controller: _distanceController,
          label: 'One-way distance',
          unit: 'km',
          minimum: 0.1,
          maximum: 10000,
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Return trip',
            style: TextStyle(fontSize: 14),
          ),
          subtitle: const Text(
            'Same distance each way',
            style: TextStyle(fontSize: 11),
          ),
          value: _returnTrip,
          onChanged: (value) {
            setState(() {
              _returnTrip = value;
              _result = null;
            });
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Extra planning fuel',
            style: TextStyle(fontSize: 14),
          ),
          subtitle: const Text(
            'Add 10% to estimated consumption',
            style: TextStyle(fontSize: 11),
          ),
          value: _addAllowance,
          onChanged: (value) {
            setState(() {
              _addAllowance = value;
              _result = null;
            });
          },
        ),
        const Divider(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Fuel remaining',
                style: TextStyle(
                  color: _dark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${_compact.format(_tankPercent)}%',
              style: const TextStyle(
                color: _blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _tankPercent,
          min: 0,
          max: 100,
          divisions: 20,
          label: '${_compact.format(_tankPercent)}%',
          onChanged: (value) {
            setState(() {
              _tankPercent = value;
              _result = null;
            });
          },
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Empty', style: TextStyle(color: _muted, fontSize: 11)),
            Text('Half', style: TextStyle(color: _muted, fontSize: 11)),
            Text('Full', style: TextStyle(color: _muted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Estimate using your fuel gauge.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    final result = _result!;
    final canPay = result.refillLitres.isFinite &&
        result.refillLitres >= _minimumRefillLitres &&
        !_openingPayment;

    return _card(
      title: 'Your estimate',
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF4FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Suggested refill',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                _litres(result.refillLitres),
                style: const TextStyle(
                  color: _dark,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'About ${_money(result.cost)}',
                style: const TextStyle(
                  color: _blue,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _detailRow(
          'Trip distance',
          _distance(result.tripDistance),
        ),
        _detailRow(
          'Planned trip fuel',
          _litres(result.plannedFuel),
        ),
        if (result.notice != null) ...[
          const SizedBox(height: 10),
          Text(
            result.notice!,
            style: const TextStyle(
              color: _dark,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
        ExpansionTile(
          key: ObjectKey(result),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: const Text(
            'View calculation details',
            style: TextStyle(
              color: _blue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            for (final row in result.details)
              _detailRow(row.key, row.value),
            const SizedBox(height: 8),
            const Text(
              'Trip fuel budget includes fuel already in your tank. '
                  'Refill cost covers only the suggested purchase.',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: canPay
                ? () => _useRefillAmount(result)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.local_gas_station_outlined),
            label: Text(
              _openingPayment ? 'Opening…' : 'Use this refill amount',
            ),
          ),
        ),
        if (result.refillLitres > 0) ...[
          const SizedBox(height: 8),
          Text(
            result.refillLitres < _minimumRefillLitres
                ? 'Minimum refill to continue: ${_litres(_minimumRefillLitres)}.'
                : 'Choose a station, then review payment.',
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          result.alternativePrice
              ? 'Estimates vary with driving conditions. '
              'Payment may use a different fuel price.'
              : 'Estimates vary with driving conditions. '
              'Review the final amount in payment.',
          style: const TextStyle(
            color: _muted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _dark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required double minimum,
    required double maximum,
  }) {
    final digits = maximum.floor().toString().length;
    final pattern = RegExp(
      '^[0-9]{0,$digits}(?:\\.[0-9]{0,2})?\$',
    );

    return TextFormField(
      key: ObjectKey(controller),
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, newValue) {
          if (!newValue.composing.isCollapsed) return newValue;
          return pattern.hasMatch(newValue.text) ? newValue : oldValue;
        }),
      ],
      decoration: _decoration(label, unit: unit),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) => _validateNumber(
        value,
        minimum: minimum,
        maximum: maximum,
        unit: unit,
      ),
      onChanged: (_) => _invalidate(),
    );
  }

  InputDecoration _decoration(String label, {String? unit}) {
    return InputDecoration(
      labelText: label,
      suffixText: unit,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      errorMaxLines: 2,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
    );
  }

  Widget _card({
    required String title,
    required List<Widget> children,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _TripEstimate {
  final String vehicleId;
  final String fuelType;
  final double refillLitres;
  final double pricePerLitre;
  final double cost;
  final double tripDistance;
  final double plannedFuel;
  final bool alternativePrice;
  final List<MapEntry<String, String>> details;
  final String? notice;

  const _TripEstimate({
    required this.vehicleId,
    required this.fuelType,
    required this.refillLitres,
    required this.pricePerLitre,
    required this.cost,
    required this.tripDistance,
    required this.plannedFuel,
    required this.alternativePrice,
    required this.details,
    this.notice,
  });
}