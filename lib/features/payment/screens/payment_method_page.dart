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

  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;

  // Credit Card Controllers
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardholderNameController = TextEditingController();

  // Touch n Go Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  // Validation states
  bool _isCardNumberValid = false;
  bool _isExpiryValid = false;
  bool _isCvvValid = false;
  bool _isCardholderNameValid = false;
  bool _isPhoneValid = false;
  bool _isPinValid = false;

  // ============================================================
  // Computed Properties
  // ============================================================

  double get _totalAmount => widget.paymentData['totalAmount'] ?? 0;

  bool get _canPay {
    if (_selectedMethod == null) return false;

    if (_selectedMethod == PaymentMethod.creditCard) {
      return _isCardNumberValid &&
          _isExpiryValid &&
          _isCvvValid &&
          _isCardholderNameValid;
    } else {
      return _isPhoneValid && _isPinValid;
    }
  }

  // ============================================================
  // Validation Methods
  // ============================================================

  bool _validateCardNumber(String value) {
    final cleaned = value.replaceAll(' ', '');
    return cleaned.length == 16 && RegExp(r'^\d+$').hasMatch(cleaned);
  }

  bool _validateExpiry(String value) {
    final regExp = RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$');
    if (!regExp.hasMatch(value)) return false;

    final parts = value.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse('20${parts[1]}');
    final now = DateTime.now();

    return year > now.year || (year == now.year && month >= now.month);
  }

  bool _validateCvv(String value) {
    return value.length == 3 && RegExp(r'^\d+$').hasMatch(value);
  }

  bool _validateCardholderName(String value) {
    return value.trim().length >= 2;
  }

  bool _validatePhone(String value) {
    final cleaned = value.replaceAll(' ', '').replaceAll('-', '');
    return cleaned.startsWith('01') && cleaned.length >= 10 && cleaned.length <= 11;
  }

  bool _validatePin(String value) {
    return value.length == 6 && RegExp(r'^\d+$').hasMatch(value);
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
        backgroundColor: const Color(0xFFE1F2FF),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Payment Method',
          style: TextStyle(
            color: Color(0xFF153B60),
            fontWeight: FontWeight.bold,
          ),
        ),
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
  // UI Components
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
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1687E8) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1687E8) : const Color(0xFFDCE5ED),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF718096),
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF153B60),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    if (_selectedMethod == PaymentMethod.creditCard) {
      return _buildCreditCardForm();
    } else {
      return _buildTouchNGoForm();
    }
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
            _buildTextField(
              controller: _cardNumberController,
              label: 'Card Number',
              hint: '1234 5678 9012 3456',
              icon: Icons.credit_card_rounded,
              keyboardType: TextInputType.number,
              maxLength: 19,
              onChanged: (value) {
                setState(() {
                  _isCardNumberValid = _validateCardNumber(value);
                });
              },
              formatter: (value) {
                final cleaned = value.replaceAll(' ', '');
                final chunks = <String>[];
                for (int i = 0; i < cleaned.length; i += 4) {
                  chunks.add(cleaned.substring(
                    i,
                    i + 4 > cleaned.length ? cleaned.length : i + 4,
                  ));
                }
                return chunks.join(' ');
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter card number';
                }
                final cleaned = value.replaceAll(' ', '');
                if (cleaned.length != 16) {
                  return 'Card number must be 16 digits';
                }
                if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
                  return 'Card number must contain only numbers';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _expiryController,
                    label: 'Expiry Date',
                    hint: 'MM/YY',
                    icon: Icons.calendar_today_rounded,
                    maxLength: 5,
                    onChanged: (value) {
                      setState(() {
                        _isExpiryValid = _validateExpiry(value);
                      });
                    },
                    formatter: (value) {
                      final cleaned = value.replaceAll('/', '');
                      if (cleaned.length >= 2) {
                        return '${cleaned.substring(0, 2)}/${cleaned.substring(2)}';
                      }
                      return cleaned;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter expiry date';
                      }
                      if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(value)) {
                        return 'Invalid format (MM/YY)';
                      }
                      final parts = value.split('/');
                      final month = int.parse(parts[0]);
                      final year = int.parse('20${parts[1]}');
                      final now = DateTime.now();
                      if (year < now.year || (year == now.year && month < now.month)) {
                        return 'Card has expired';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _cvvController,
                    label: 'CVV',
                    hint: '123',
                    icon: Icons.security_rounded,
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    obscureText: true,
                    onChanged: (value) {
                      setState(() {
                        _isCvvValid = _validateCvv(value);
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter CVV';
                      }
                      if (value.length != 3) {
                        return 'CVV must be 3 digits';
                      }
                      if (!RegExp(r'^\d+$').hasMatch(value)) {
                        return 'CVV must contain only numbers';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _cardholderNameController,
              label: 'Cardholder Name',
              hint: 'AHMAD BIN ABDULLAH',
              icon: Icons.person_rounded,
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                setState(() {
                  _isCardholderNameValid = _validateCardholderName(value);
                });
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter cardholder name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
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
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '012-3456789',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                setState(() {
                  _isPhoneValid = _validatePhone(value);
                });
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter phone number';
                }
                final cleaned = value.replaceAll(' ', '').replaceAll('-', '');
                if (!cleaned.startsWith('01')) {
                  return 'Must start with 01';
                }
                if (cleaned.length < 10 || cleaned.length > 11) {
                  return 'Invalid phone number';
                }
                if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
                  return 'Must contain only numbers';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _pinController,
              label: 'TnG PIN',
              hint: '123456',
              icon: Icons.lock_rounded,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              onChanged: (value) {
                setState(() {
                  _isPinValid = _validatePin(value);
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter TnG PIN';
                }
                if (value.length != 6) {
                  return 'PIN must be 6 digits';
                }
                if (!RegExp(r'^\d+$').hasMatch(value)) {
                  return 'PIN must contain only numbers';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Reusable TextField
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
    bool obscureText = false,
    required Function(String) onChanged,
    String Function(String)? formatter,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      maxLength: maxLength,
      validator: validator,
      onChanged: (value) {
        if (formatter != null) {
          final formatted = formatter(value);
          if (formatted != value) {
            controller.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
        }
        onChanged(controller.text);
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1687E8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        counterText: '',
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

  // ============================================================
  // Pay Button
  // ============================================================

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing || !_canPay ? null : _handlePayment,
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
          'Pay Now',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  bool _validateForm() {
    if (_selectedMethod == PaymentMethod.creditCard) {

      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      if (cardNumber.length != 16 || !RegExp(r'^\d+$').hasMatch(cardNumber)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 16-digit card number'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return false;
      }

      final expiry = _expiryController.text;
      if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(expiry)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid expiry date (MM/YY)'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return false;
      }

      final cvv = _cvvController.text;
      if (cvv.length != 3 || !RegExp(r'^\d+$').hasMatch(cvv)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 3-digit CVV'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return false;
      }

      final name = _cardholderNameController.text.trim();
      if (name.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter cardholder name'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return false;
      }

      return true;
    } else {
      final phone = _phoneController.text.replaceAll(' ', '').replaceAll('-', '');
      if (!phone.startsWith('01') || phone.length < 10 || phone.length > 11) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid phone number (01X-XXXXXXX)'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return false;
      }

      final pin = _pinController.text;
      if (pin.length != 6 || !RegExp(r'^\d+$').hasMatch(pin)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 6-digit TnG PIN'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return false;
      }

      return true;
    }
  }

  // ============================================================
  // Payment Processing
  // ============================================================

  void _handlePayment() async {
    if (!_validateForm()) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final transaction = await _paymentService.processPayment(
        userId: widget.paymentData['userId'],
        placeId: widget.paymentData['placeId'],
        stationName: widget.paymentData['stationName'],
        stationAddress: widget.paymentData['stationAddress'],
        vehicleId: widget.paymentData['vehicleId'],
        pumpNumber: widget.paymentData['pumpNumber'],
        fuelType: widget.paymentData['fuelType'],
        quantityLiters: widget.paymentData['quantityLiters'],
        pricePerLiter: widget.paymentData['pricePerLiter'],
        voucherId: widget.paymentData['voucherId'],
        paymentMethod: _selectedMethod!.label,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptPage(transaction: transaction),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}