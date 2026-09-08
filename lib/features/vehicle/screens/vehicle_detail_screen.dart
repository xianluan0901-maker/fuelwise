import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';
import 'vehicle_form_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<VehicleDetailScreen> createState() =>
      _VehicleDetailScreenState();
}

class _VehicleDetailScreenState
    extends State<VehicleDetailScreen> {
  final VehicleService _vehicleService = VehicleService();

  late Vehicle _vehicle;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
  }

  Future<void> _editVehicle() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleFormScreen(
          vehicle: _vehicle,
        ),
      ),
    );

    if (updated != true || !mounted) return;

    try {
      final vehicles =
      await _vehicleService.getVehicles();

      final refreshedVehicle = vehicles.firstWhere(
            (vehicle) => vehicle.id == _vehicle.id,
      );

      if (!mounted) return;

      setState(() {
        _vehicle = refreshedVehicle;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vehicle updated successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vehicle was updated, but the details could not be refreshed.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteVehicle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete vehicle?'),
          content: Text(
            'Are you sure you want to delete '
                '${_vehicle.vehicleName} '
                '(${_vehicle.plateNumber})?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || _isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _vehicleService.deleteVehicle(_vehicle);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to delete the vehicle.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Color _fuelColour() {
    switch (_vehicle.fuelType) {
      case 'RON97':
        return const Color(0xFFF5A623);

      case 'Diesel':
        return const Color(0xFF7B61D1);

      case 'BUDI95':
        return const Color(0xFF1687E8);

      case 'RON95':
      default:
        return const Color(0xFF20A978);
    }
  }

  String _displayValue(Object? value) {
    if (value == null) return 'Not provided';

    final text = value.toString().trim();

    return text.isEmpty ? 'Not provided' : text;
  }

  @override
  Widget build(BuildContext context) {
    final fuelColour = _fuelColour();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE4F3FF),
        foregroundColor: const Color(0xFF153B60),
        elevation: 0,
        title: const Text(
          'Vehicle Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1687E8),
                      Color(0xFF58B6F6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.18,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _vehicle.vehicleName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _vehicle.plateNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    if (_vehicle.isDefault) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.18,
                          ),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'DEFAULT VEHICLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Container(
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
                  children: [
                    _buildDetailRow(
                      icon: Icons.business_rounded,
                      label: 'Brand',
                      value: _displayValue(_vehicle.brand),
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.directions_car_filled_rounded,
                      label: 'Model',
                      value: _displayValue(_vehicle.model),
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.calendar_month_rounded,
                      label: 'Manufacture Year',
                      value: _displayValue(
                        _vehicle.manufactureYear,
                      ),
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.local_gas_station_rounded,
                      label: 'Fuel Type',
                      value: _vehicle.fuelType,
                      iconColour: fuelColour,
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.speed_rounded,
                      label: 'Fuel Efficiency',
                      value: _vehicle.fuelEfficiency == null
                          ? 'Not provided'
                          : '${_vehicle.fuelEfficiency!.toStringAsFixed(1)} km/L',
                    ),
                    _buildDivider(),
                    _buildDetailRow(
                      icon: Icons.oil_barrel_rounded,
                      label: 'Tank Capacity',
                      value: _vehicle.tankCapacity == null
                          ? 'Not provided'
                          : '${_vehicle.tankCapacity!.toStringAsFixed(1)} L',
                    ),
                    if (_vehicle.createdAt != null) ...[
                      _buildDivider(),
                      _buildDetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'Added On',
                        value: DateFormat(
                          'dd MMM yyyy',
                        ).format(
                          _vehicle.createdAt!.toLocal(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isDeleting
                          ? null
                          : _deleteVehicle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(
                          color: Colors.redAccent,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      icon: _isDeleting
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(
                        Icons.delete_outline_rounded,
                      ),
                      label: const Text('Delete'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                      _isDeleting ? null : _editVehicle,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF1687E8),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit Vehicle'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 25,
      color: Color(0xFFE9EEF3),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color iconColour = const Color(0xFF1687E8),
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColour.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColour,
            size: 21,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8795A3),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF153B60),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}