import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/profile_button.dart';
import '../widgets/top_navbar.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AddPaymentMethodBookingScreen extends StatefulWidget {
  const AddPaymentMethodBookingScreen({super.key});

  @override
  _AddPaymentMethodBookingScreenState createState() => _AddPaymentMethodBookingScreenState();
}

class _AddPaymentMethodBookingScreenState extends State<AddPaymentMethodBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expirationDateController = TextEditingController();
  String? _selectedCardType;
  bool _isPredefined = false;
  bool _isLoading = false;
  final List<String> _cardTypes = ['Visa', 'Mastercard'];

  @override
  void dispose() {
    _identifierController.dispose();
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expirationDateController.dispose();
    super.dispose();
  }

  void _formatCardNumber(String value) {
    String newValue = value.replaceAll(RegExp(r'\D'), '');
    if (newValue.length > 16) {
      newValue = newValue.substring(0, 16);
    }
    final formatted = newValue.replaceAllMapped(RegExp(r".{4}"), (match) => "${match.group(0)} ");
    _cardNumberController.value = TextEditingValue(
      text: formatted.trim(),
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _formatExpirationDate(String value) {
    String newValue = value.replaceAll(RegExp(r'\D'), '');
    if (newValue.length > 4) {
      newValue = newValue.substring(0, 4);
    }
    if (newValue.length >= 2) {
      newValue = "${newValue.substring(0, 2)}/${newValue.substring(2)}";
    }
    _expirationDateController.value = TextEditingValue(
      text: newValue,
      selection: TextSelection.collapsed(offset: newValue.length),
    );
  }

  int _getCardTypeId(String cardType) {
    switch (cardType) {
      case 'Visa':
        return 1;
      case 'Mastercard':
        return 2;
      default:
        return 0;
    }
  }

  void _savePaymentMethod() async {
    if (!_formKey.currentState!.validate()) return;
    final authService = AuthService();
    final token = await authService.getToken();
    if (token != null) {
      final newPaymentMethod = {
        'identifier': _identifierController.text.trim().isEmpty ? null : _identifierController.text.trim(),
        'name': _cardHolderController.text.trim(),
        'number': _cardNumberController.text.replaceAll(' ', '').trim(),
        'validity': _expirationDateController.text.trim(),
        'payment_method_type_id': _getCardTypeId(_selectedCardType!),
        'predefined': _isPredefined,
      };
      setState(() => _isLoading = true);
      try {
        final response = await ApiService().addPaymentMethod(token, newPaymentMethod);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment method added successfully!')),
        );
        Navigator.pop(context, response.data['payment_method']);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add payment method: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: const TopNavbar(title: 'Add Payment Method', backgroundColor: Colors.orange),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _identifierController,
                label: 'Identifier (optional)',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _cardHolderController,
                label: 'Cardholder Name',
                validator: (value) => value == null || value.isEmpty ? 'Cardholder name is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _cardNumberController,
                label: 'Card Number',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _formatCardNumber,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Card number is required';
                  if (value.replaceAll(' ', '').length != 16) return 'Card number must be 16 digits';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _expirationDateController,
                label: 'Expiration Date (MM/YY)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _formatExpirationDate,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Expiration date is required';
                  if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) return 'Invalid format (MM/YY)';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCardType,
                onChanged: (value) {
                  setState(() {
                    _selectedCardType = value!;
                  });
                },
                items: _cardTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Card Type',
                  labelStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                iconEnabledColor: Colors.white,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Predefined Payment Method', style: TextStyle(color: Colors.white)),
                  Switch(
                    value: _isPredefined,
                    onChanged: (bool value) {
                      setState(() {
                        _isPredefined = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 180,
                    child: ProfileButton(
                      icon: Icons.save_alt_rounded,
                      label: _isLoading ? 'Saving...' : 'Save',
                      onTap: _isLoading ? () {} : _savePaymentMethod,
                    ),
                  ),
                  SizedBox(
                    width: 135,
                    child: ProfileButton(
                      icon: Icons.cancel,
                      label: 'Cancel',
                      onTap: () => Navigator.pop(context),
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
}
