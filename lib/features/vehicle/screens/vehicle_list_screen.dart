import 'package:flutter/material.dart';

import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';
import 'vehicle_form_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() {
    return _VehicleListScreenState();
  }
}

class _VehicleListScreenState
    extends State<VehicleListScreen> {
  final VehicleService _vehicleService =
  VehicleService();

  List<Vehicle> _vehicles = [];

  bool _isLoading = true;
  String? _errorMessage;
  String? _processingVehicleId;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vehicles =
      await _vehicleService.getVehicles();

      if (!mounted) return;

      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
        'Unable to retrieve your vehicles.';
      });
    }
  }

  Future<void> _openAddVehicle() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const VehicleFormScreen(),
      ),
    );

    if (added == true) {
      await _loadVehicles();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vehicle added successfully.',
          ),
        ),
      );
    }
  }

  Future<void> _openEditVehicle(
      Vehicle vehicle,
      ) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VehicleFormScreen(vehicle: vehicle),
      ),
    );

    if (updated == true) {
      await _loadVehicles();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vehicle updated successfully.',
          ),
        ),
      );
    }
  }

  Future<void> _setDefaultVehicle(
      Vehicle vehicle,
      ) async {
    if (vehicle.isDefault ||
        _processingVehicleId != null) {
      return;
    }

    setState(() {
      _processingVehicleId = vehicle.id;
    });

    try {
      await _vehicleService.setDefaultVehicle(
        vehicle.id,
      );

      await _loadVehicles();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${vehicle.vehicleName} is now your default vehicle.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to change the default vehicle.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingVehicleId = null;
        });
      }
    }
  }

  Future<void> _confirmDelete(
      Vehicle vehicle,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete vehicle?'),
          content: Text(
            'Are you sure you want to delete '
                '${vehicle.vehicleName} '
                '(${vehicle.plateNumber})?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                Colors.redAccent,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true ||
        _processingVehicleId != null) {
      return;
    }

    setState(() {
      _processingVehicleId = vehicle.id;
    });

    try {
      await _vehicleService.deleteVehicle(
        vehicle,
      );

      await _loadVehicles();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vehicle deleted successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to delete the vehicle.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingVehicleId = null;
        });
      }
    }
  }

  Color _fuelColour(String fuelType) {
    switch (fuelType) {
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
      backgroundColor:
      const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
        const Color(0xFFE1F2FF),
        centerTitle: true,
        title: const Text(
          'My Vehicles',
          style: TextStyle(
            color: Color(0xFF153B60),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddVehicle,
        backgroundColor:
        const Color(0xFF1687E8),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Vehicle',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadVehicles,
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
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 50,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadVehicles,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Try Again'),
            ),
          ),
        ],
      );
    }

    if (_vehicles.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        100,
      ),
      children: [
        _buildSummary(),
        const SizedBox(height: 18),
        for (final vehicle in _vehicles)
          Padding(
            padding:
            const EdgeInsets.only(bottom: 14),
            child: _buildVehicleCard(vehicle),
          ),
      ],
    );
  }

  Widget _buildSummary() {
    final defaultVehicle = _vehicles
        .where((vehicle) => vehicle.isDefault)
        .firstOrNull;

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
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF1687E8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  '${_vehicles.length} '
                      '${_vehicles.length == 1 ? 'Vehicle' : 'Vehicles'}',
                  style: const TextStyle(
                    color: Color(0xFF153B60),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  defaultVehicle == null
                      ? 'No default vehicle selected'
                      : 'Default: ${defaultVehicle.vehicleName}',
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(
      Vehicle vehicle,
      ) {
    final fuelColour =
    _fuelColour(vehicle.fuelType);

    final isProcessing =
        _processingVehicleId == vehicle.id;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: vehicle.isDefault
              ? const Color(0xFF1687E8)
              : const Color(0xFFE4EBF2),
          width: vehicle.isDefault ? 1.5 : 1,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: fuelColour.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.directions_car_rounded,
                    color: fuelColour,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vehicle.vehicleName,
                              style: const TextStyle(
                                color:
                                Color(0xFF153B60),
                                fontSize: 17,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                          if (vehicle.isDefault)
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFE1F2FF,
                                ),
                                borderRadius:
                                BorderRadius.circular(
                                  20,
                                ),
                              ),
                              child: const Text(
                                'DEFAULT',
                                style: TextStyle(
                                  color: Color(
                                    0xFF1687E8,
                                  ),
                                  fontSize: 9,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicle.plateNumber,
                        style: const TextStyle(
                          color: Color(0xFF536B7E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_vehicleDescription(vehicle)
                          .isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          _vehicleDescription(vehicle),
                          style: const TextStyle(
                            color: Color(0xFF8A98A6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            child: Row(
              children: [
                _buildInformationChip(
                  icon:
                  Icons.local_gas_station_rounded,
                  label: vehicle.fuelType,
                  colour: fuelColour,
                ),
                if (vehicle.fuelEfficiency !=
                    null) ...[
                  const SizedBox(width: 8),
                  _buildInformationChip(
                    icon: Icons.speed_rounded,
                    label:
                    '${vehicle.fuelEfficiency!.toStringAsFixed(1)} km/L',
                    colour:
                    const Color(0xFF1687E8),
                  ),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  enabled: !isProcessing,
                  onSelected: (action) {
                    switch (action) {
                      case 'default':
                        _setDefaultVehicle(vehicle);
                        break;

                      case 'edit':
                        _openEditVehicle(vehicle);
                        break;

                      case 'delete':
                        _confirmDelete(vehicle);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!vehicle.isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color:
                              Color(0xFFF5A623),
                            ),
                            SizedBox(width: 10),
                            Text('Set as Default'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            color: Color(0xFF1687E8),
                          ),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: isProcessing
                      ? const SizedBox(
                    width: 23,
                    height: 23,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _vehicleDescription(
      Vehicle vehicle,
      ) {
    return [
      vehicle.brand,
      vehicle.model,
      vehicle.manufactureYear?.toString(),
    ]
        .where(
          (value) =>
      value != null &&
          value.trim().isNotEmpty,
    )
        .join(' • ');
  }

  Widget _buildInformationChip({
    required IconData icon,
    required String label,
    required Color colour,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: colour,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            label,
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

  Widget _buildEmptyState() {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 100),
        Container(
          width: 105,
          height: 105,
          decoration: const BoxDecoration(
            color: Color(0xFFE1F2FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_car_outlined,
            color: Color(0xFF1687E8),
            size: 55,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'No vehicles yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF153B60),
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add your first vehicle and manage its '
              'fuel information here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF718096),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        ElevatedButton.icon(
          onPressed: _openAddVehicle,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add First Vehicle'),
        ),
      ],
    );
  }
}