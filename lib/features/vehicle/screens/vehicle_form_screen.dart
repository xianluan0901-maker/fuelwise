import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';

class VehicleFormScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const VehicleFormScreen({
    super.key,
    this.vehicle,
  });

  bool get isEditing => vehicle != null;

  @override
  State<VehicleFormScreen> createState() {
    return _VehicleFormScreenState();
  }
}

class _VehicleFormScreenState
    extends State<VehicleFormScreen> {
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final VehicleService _vehicleService =
  VehicleService();

  late final TextEditingController
  _vehicleNameController;

  late final TextEditingController
  _plateNumberController;

  late final TextEditingController
  _brandController;

  late final TextEditingController
  _modelController;

  late final TextEditingController
  _yearController;

  late final TextEditingController
  _fuelEfficiencyController;

  late final TextEditingController
  _tankCapacityController;

  String _selectedFuelType = 'RON95';
  bool _isSaving = false;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();

    final vehicle = widget.vehicle;

    _vehicleNameController =
        TextEditingController(
          text: vehicle?.vehicleName ?? '',
        );

    _plateNumberController =
        TextEditingController(
          text: vehicle?.plateNumber ?? '',
        );

    _brandController = TextEditingController(
      text: vehicle?.brand ?? '',
    );

    _modelController = TextEditingController(
      text: vehicle?.model ?? '',
    );

    _yearController = TextEditingController(
      text: vehicle?.manufactureYear?.toString() ??
          '',
    );

    _fuelEfficiencyController =
        TextEditingController(
          text: vehicle?.fuelEfficiency?.toString() ??
              '',
        );

    _tankCapacityController =
        TextEditingController(
          text: vehicle?.tankCapacity?.toString() ??
              '',
        );

    _selectedFuelType =
        vehicle?.fuelType ?? 'RON95';
  }

  @override
  void dispose() {
    _vehicleNameController.dispose();
    _plateNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _fuelEfficiencyController.dispose();
    _tankCapacityController.dispose();

    super.dispose();
  }

  Future<void> _saveVehicle() async {
    final valid =
        _formKey.currentState?.validate() ?? false;

    if (!valid || _isSaving) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final manufactureYear = _parseInt(
        _yearController.text,
      );

      final fuelEfficiency = _parseDouble(
        _fuelEfficiencyController.text,
      );

      final tankCapacity = _parseDouble(
        _tankCapacityController.text,
      );

      if (_isEditing) {
        await _vehicleService.updateVehicle(
          vehicleId: widget.vehicle!.id,
          vehicleName:
          _vehicleNameController.text,
          plateNumber:
          _plateNumberController.text,
          brand: _brandController.text,
          model: _modelController.text,
          manufactureYear: manufactureYear,
          fuelType: _selectedFuelType,
          fuelEfficiency: fuelEfficiency,
          tankCapacity: tankCapacity,
        );
      } else {
        await _vehicleService.addVehicle(
          vehicleName:
          _vehicleNameController.text,
          plateNumber:
          _plateNumberController.text,
          brand: _brandController.text,
          model: _modelController.text,
          manufactureYear: manufactureYear,
          fuelType: _selectedFuelType,
          fuelEfficiency: fuelEfficiency,
          tankCapacity: tankCapacity,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      if (!mounted) return;

      String message = error.message;

      // PostgreSQL unique-constraint error.
      if (error.code == '23505') {
        message =
        'This plate number is already registered.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Unable to update vehicle.'
                : 'Unable to add vehicle.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  int? _parseInt(String value) {
    final cleaned = value.trim();

    if (cleaned.isEmpty) {
      return null;
    }

    return int.tryParse(cleaned);
  }

  double? _parseDouble(String value) {
    final cleaned = value.trim();

    if (cleaned.isEmpty) {
      return null;
    }

    return double.tryParse(cleaned);
  }

  String? _requiredValidator(
      String? value,
      String fieldName,
      ) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName.';
    }

    return null;
  }

  String? _yearValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final year = int.tryParse(value.trim());
    final maximumYear = DateTime.now().year + 1;

    if (year == null ||
        year < 1886 ||
        year > maximumYear) {
      return 'Enter a valid vehicle year.';
    }

    return null;
  }

  String? _positiveNumberValidator(
      String? value,
      String fieldName,
      ) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final number = double.tryParse(
      value.trim(),
    );

    if (number == null || number <= 0) {
      return 'Enter a valid $fieldName.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE1F2FF),
        centerTitle: true,
        title: Text(
          _isEditing
              ? 'Edit Vehicle'
              : 'Add Vehicle',
          style: const TextStyle(
            color: Color(0xFF153B60),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            20,
            18,
            40,
          ),
          children: [
            _buildHeader(),
            const SizedBox(height: 22),
            _buildSection(
              title: 'Vehicle Information',
              icon: Icons.directions_car_rounded,
              children: [
                _buildTextField(
                  controller:
                  _vehicleNameController,
                  label: 'Vehicle name',
                  hint: 'Example: My Bezza',
                  icon: Icons.label_outline_rounded,
                  validator: (value) {
                    return _requiredValidator(
                      value,
                      'a vehicle name',
                    );
                  },
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller:
                  _plateNumberController,
                  label: 'Plate number',
                  hint: 'Example: SAB 1234 A',
                  icon:
                  Icons.pin_outlined,
                  textCapitalization:
                  TextCapitalization.characters,
                  inputFormatters: [
                    UpperCaseTextFormatter(),
                  ],
                  validator: (value) {
                    return _requiredValidator(
                      value,
                      'a plate number',
                    );
                  },
                ),
                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller:
                        _brandController,
                        label: 'Brand',
                        hint: 'Perodua',
                        icon: Icons.business_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller:
                        _modelController,
                        label: 'Model',
                        hint: 'Bezza',
                        icon:
                        Icons.car_repair_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: _yearController,
                  label: 'Manufacture year',
                  hint: 'Example: 2023',
                  icon:
                  Icons.calendar_month_rounded,
                  keyboardType:
                  TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly,
                    LengthLimitingTextInputFormatter(
                      4,
                    ),
                  ],
                  validator: _yearValidator,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildSection(
              title: 'Fuel Information',
              icon:
              Icons.local_gas_station_rounded,
              children: [
                _buildFuelTypeSelector(),
                const SizedBox(height: 15),
                _buildTextField(
                  controller:
                  _fuelEfficiencyController,
                  label: 'Fuel efficiency',
                  hint: 'Example: 18.5',
                  suffix: 'km/L',
                  icon: Icons.speed_rounded,
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
                  validator: (value) {
                    return _positiveNumberValidator(
                      value,
                      'fuel efficiency',
                    );
                  },
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller:
                  _tankCapacityController,
                  label: 'Tank capacity',
                  hint: 'Example: 36',
                  suffix: 'L',
                  icon:
                  Icons.oil_barrel_outlined,
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
                  validator: (value) {
                    return _positiveNumberValidator(
                      value,
                      'tank capacity',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                _isSaving ? null : _saveVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF1687E8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                  width: 19,
                  height: 19,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Icon(
                  _isEditing
                      ? Icons.save_rounded
                      : Icons.add_rounded,
                ),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : _isEditing
                      ? 'Save Changes'
                      : 'Add Vehicle',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
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
            width: 53,
            height: 53,
            decoration: const BoxDecoration(
              color: Color(0xFF1687E8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'Update your vehicle'
                      : 'Register a vehicle',
                  style: const TextStyle(
                    color: Color(0xFF153B60),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEditing
                      ? 'Keep your vehicle information accurate.'
                      : 'Add information for fuel calculations and payments.',
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
              Icon(
                icon,
                color: const Color(0xFF1687E8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF153B60),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffix,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization =
        TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(icon),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildFuelTypeSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedFuelType,
      decoration: InputDecoration(
        labelText: 'Preferred fuel type',
        prefixIcon: const Icon(
          Icons.local_gas_station_rounded,
        ),
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
      items: const [
        DropdownMenuItem(
          value: 'RON95',
          child: Text('RON95'),
        ),
        DropdownMenuItem(
          value: 'RON97',
          child: Text('RON97'),
        ),
        DropdownMenuItem(
          value: 'Diesel',
          child: Text('Diesel'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedFuelType = value;
          });
        }
      },
    );
  }
}

class UpperCaseTextFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}