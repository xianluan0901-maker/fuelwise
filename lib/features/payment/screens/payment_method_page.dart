// features/payment/screens/payment_method_page.dart

import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import 'receipt_page.dart';

class PaymentMethodPage extends StatefulWidget {
  final Map<String, dynamic> paymentData;

  const PaymentMethodPage({
    super.key,
    required this.paymentData,
  });

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  final PaymentService _paymentService = PaymentService();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;

  // ============================================================
  // Track whether each field has been touched
  // ============================================================

  final Map<String, bool> _fieldTouched = {
    'cardNumber': false,
    'expiry': false,
    'cvv': false,
    'cardholderName': false,
    'phone': false,
    'pin': false,
  };

  // ============================================================
  // Credit Card Controllers
  // ============================================================

  final TextEditingController _cardNumberController =
  TextEditingController();

  final TextEditingController _expiryController =
  TextEditingController();

  final TextEditingController _cvvController =
  TextEditingController();

  final TextEditingController _cardholderNameController =
  TextEditingController();

  // ============================================================
  // Touch n Go Controllers
  // ============================================================

  final TextEditingController _phoneController =
  TextEditingController();

  final TextEditingController _pinController =
  TextEditingController();

  // ============================================================
  // Computed Properties
  // ============================================================

  double get _totalAmount => widget.paymentData['totalAmount'] ?? 0;

  // ============================================================
  // Validation Helpers
  // ============================================================

  bool _isTouched(String field) {
    return _fieldTouched[field] ?? false;
  }

  void _markFieldTouched(String field) {
    if (!_isTouched(field)) {
      setState(() {
        _fieldTouched[field] = true;
      });
    }
  }

  // ============================================================
  // Validation Methods
  // ============================================================

  String? validateCardNumber(String? value) {
    // Do not show error before user interacts with this field.
    if (!_isTouched('cardNumber')) {
      return null;
    }

    if (value == null || value.isEmpty) {
      return 'Please enter card number';
    }

    final cleaned = value.replaceAll(' ', '');

    if (cleaned.length != 16) {
      return 'Card number must be 16 digits';
    }

    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Numbers only, no letters or symbols';
    }

    return null;
  }

  String? validateExpiry(String? value) {
    // Do not show error before user interacts with this field.
    if (!_isTouched('expiry')) {
      return null;
    }

    if (value == null || value.isEmpty) {
      return 'Please enter expiry date';
    }

    final regExp = RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$');

    if (!regExp.hasMatch(value)) {
      return 'Invalid format (MM/YY)';
    }

    final parts = value.split('/');
    final month = int.parse(parts[0]);
    final yearTwoDigits = int.parse(parts[1]);

    final currentYear = DateTime.now().year;
    final currentTwoDigits = currentYear % 100;
    final currentCentury = (currentYear ~/ 100) * 100;

    int year;

    if (yearTwoDigits > currentTwoDigits + 5) {
      year = currentCentury - 100 + yearTwoDigits;
    } else {
      year = currentCentury + yearTwoDigits;
    }

    final expiryDate = DateTime(year, month);
    final now = DateTime.now();

    if (expiryDate.isBefore(
      DateTime(now.year, now.month, 1),
    )) {
      return 'Card has expired, please check';
    }

    return null;
  }

  String? validateCvv(String? value) {
    // Do not show error before user interacts with this field.
    if (!_isTouched('cvv')) {
      return null;
    }

    if (value == null || value.isEmpty) {
      return 'Please enter CVV';
    }

    if (value.length != 3) {
      return 'CVV must be 3 digits';
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Numbers only';
    }

    return null;
  }

  String? validateCardholderName(String? value) {
    // Do not show error before user interacts with this field.
    if (!_isTouched('cardholderName')) {
      return null;
    }

    if (value == null || value.trim().isEmpty) {
      return 'Please enter cardholder name';
    }

    final trimmed = value.trim();

    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmed)) {
      return 'Letters and spaces only';
    }

    return null;
  }

  String? validatePhone(String? value) {
    // Do not show error before user interacts with this field.
    if (!_isTouched('phone')) {
      return null;
    }

    if (value == null || value.trim().isEmpty) {
      return 'Please enter phone number';
    }

    final cleaned = value
        .replaceAll(' ', '')
        .replaceAll('-', '');

    if (!cleaned.startsWith('01')) {
      return 'Must start with 01';
    }

    if (cleaned.length < 10 || cleaned.length > 11) {
      return 'Phone must be 10-11 digits';
    }

    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Numbers only';
    }

    return null;
  }

  String? validatePin(String? value) {
    // Do not show error before user interacts with this field.
    if (!_isTouched('pin')) {
      return null;
    }

    if (value == null || value.isEmpty) {
      return 'Please enter TnG PIN';
    }

    if (value.length != 6) {
      return 'PIN must be 6 digits';
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Numbers only';
    }

    return null;
  }

  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();

    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Payment Method'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAmountSection(),

            const SizedBox(height: 20),

            _buildMethodSelector(),

            const SizedBox(height: 20),

            if (_selectedMethod != null) _buildPaymentForm(),

            const SizedBox(height: 24),

            _buildPayButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Amount Section
  // ============================================================

  Widget _buildAmountSection() {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              color: Color(0xFF153B60),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'RM${_totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1687E8),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Payment Method Selector
  // ============================================================

  Widget _buildMethodSelector() {
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
          const Text(
            'Select Payment Method',
            style: TextStyle(
              color: Color(0xFF153B60),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildMethodChip(
                  method: PaymentMethod.creditCard,
                  icon: Icons.credit_card_rounded,
                  label: 'Credit/Debit Card',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildMethodChip(
                  method: PaymentMethod.touchNGo,
                  icon: Icons.qr_code_rounded,
                  label: 'Touch n Go',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChip({
    required PaymentMethod method,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedMethod == method;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = method;

          // Reset validation state when switching payment method.
          _fieldTouched.updateAll(
                (key, value) => false,
          );
        });

        // Reset form validation state.
        _formKey.currentState?.reset();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1687E8)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1687E8)
                : const Color(0xFFDCE5ED),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF718096),
              size: 28,
            ),

            const SizedBox(height: 4),

            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF153B60),
                fontSize: 12,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Payment Form
  // ============================================================

  Widget _buildPaymentForm() {
    if (_selectedMethod == PaymentMethod.creditCard) {
      return _buildCreditCardForm();
    }

    return _buildTouchNGoForm();
  }

  // ============================================================
  // Credit Card Form
  // ============================================================

  Widget _buildCreditCardForm() {
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
      child: Form(
        key: _formKey,

        // Validation is controlled by _fieldTouched.
        autovalidateMode: AutovalidateMode.onUserInteraction,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Credit / Debit Card Details',
              style: TextStyle(
                color: Color(0xFF153B60),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // ====================================================
            // Card Number
            // ====================================================

            TextFormField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              maxLength: 19,
              validator: validateCardNumber,

              onChanged: (value) {
                _markFieldTouched('cardNumber');

                // Auto-format: add space every 4 digits.
                final cleaned = value.replaceAll(' ', '');

                final chunks = <String>[];

                for (int i = 0; i < cleaned.length; i += 4) {
                  final end =
                  i + 4 > cleaned.length
                      ? cleaned.length
                      : i + 4;

                  chunks.add(
                    cleaned.substring(i, end),
                  );
                }

                final formatted = chunks.join(' ');

                if (formatted != _cardNumberController.text) {
                  _cardNumberController.value =
                      TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                }
              },

              decoration: _buildInputDecoration(
                label: 'Card Number',
                hint: '1234 5678 9012 3456',
                icon: Icons.credit_card_rounded,
              ),
            ),

            const SizedBox(height: 14),

            // ====================================================
            // Expiry + CVV
            // ====================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Expiry Date
                Expanded(
                  flex: 6,
                  child: TextFormField(
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    validator: validateExpiry,

                    onChanged: (value) {
                      _markFieldTouched('expiry');

                      // Auto-add slash after MM.
                      final cleaned =
                      value.replaceAll('/', '');

                      if (cleaned.length >= 2 &&
                          !value.contains('/')) {
                        final formatted =
                            '${cleaned.substring(0, 2)}/${cleaned.substring(2)}';

                        _expiryController.value =
                            TextEditingValue(
                              text: formatted,
                              selection:
                              TextSelection.collapsed(
                                offset: formatted.length,
                              ),
                            );
                      }
                    },

                    decoration: _buildInputDecoration(
                      label: 'Expiry Date',
                      hint: 'MM/YY',
                      icon: Icons.calendar_today_rounded,

                      // Important:
                      // Allow expiry error message to wrap
                      // instead of being cut off.
                      errorMaxLines: 2,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // CVV
                Expanded(
                  flex: 4,
                  child: TextFormField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    obscureText: true,
                    validator: validateCvv,

                    onChanged: (value) {
                      _markFieldTouched('cvv');
                    },

                    decoration: _buildInputDecoration(
                      label: 'CVV',
                      hint: '123',
                      icon: Icons.security_rounded,

                      errorMaxLines: 2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ====================================================
            // Cardholder Name
            // ====================================================

            TextFormField(
              controller: _cardholderNameController,
              textCapitalization: TextCapitalization.characters,
              validator: validateCardholderName,

              onChanged: (value) {
                _markFieldTouched('cardholderName');
              },

              decoration: _buildInputDecoration(
                label: 'Cardholder Name',
                hint: 'AHMAD BIN ABDULLAH',
                icon: Icons.person_rounded,
                errorMaxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Touch n Go Form
  // ============================================================

  Widget _buildTouchNGoForm() {
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
      child: Form(
        key: _formKey,

        autovalidateMode: AutovalidateMode.onUserInteraction,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Touch n Go Details',
              style: TextStyle(
                color: Color(0xFF153B60),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // ====================================================
            // Phone Number
            // ====================================================

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: validatePhone,

              onChanged: (value) {
                _markFieldTouched('phone');
              },

              decoration: _buildInputDecoration(
                label: 'Phone Number',
                hint: '012-3456789',
                icon: Icons.phone_rounded,
                errorMaxLines: 2,
              ),
            ),

            const SizedBox(height: 14),

            // ====================================================
            // TnG PIN
            // ====================================================

            TextFormField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              validator: validatePin,

              onChanged: (value) {
                _markFieldTouched('pin');
              },

              decoration: _buildInputDecoration(
                label: 'TnG PIN',
                hint: '123456',
                icon: Icons.lock_rounded,
                errorMaxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Reusable Input Decoration
  // ============================================================

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    int errorMaxLines = 2,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixIcon: Icon(
        icon,
        color: const Color(0xFF1687E8),
      ),

      filled: true,
      fillColor: const Color(0xFFF8FAFC),

      counterText: '',

      isDense: true,

      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 12,
      ),

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

      // Important for long error messages.
      errorMaxLines: errorMaxLines,

      errorStyle: const TextStyle(
        color: Colors.redAccent,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
    );
  }

  // ============================================================
  // Pay Button
  // ============================================================

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
        _isProcessing ? null : _handlePayment,

        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
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
          'Pay Now',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ⭐ Payment Processing（只加了 vehicleName 和 vehiclePlate）
  // ============================================================

  void _handlePayment() async {
    // ==========================================================
    // User pressed Pay Now.
    // At this point, show validation errors for ALL fields.
    // ==========================================================

    setState(() {
      _fieldTouched.updateAll(
            (key, value) => true,
      );
    });

    final isValid =
        _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in all required fields correctly',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final transaction =
      await _paymentService.processPayment(
        userId: widget.paymentData['userId'],
        placeId: widget.paymentData['placeId'],
        stationName:
        widget.paymentData['stationName'],
        stationAddress:
        widget.paymentData['stationAddress'],
        vehicleId:
        widget.paymentData['vehicleId'],

        // ⭐ 新增：传递车辆名称和车牌
        vehicleName:
        widget.paymentData['vehicleName'],
        vehiclePlate:
        widget.paymentData['vehiclePlate'],

        pumpNumber:
        widget.paymentData['pumpNumber'],
        fuelType:
        widget.paymentData['fuelType'],
        quantityLiters:
        widget.paymentData['quantityLiters'],
        pricePerLiter:
        widget.paymentData['pricePerLiter'],
        voucherId:
        widget.paymentData['voucherId'],
        paymentMethod:
        _selectedMethod!.label,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ReceiptPage(
                transaction: transaction,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment failed: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
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