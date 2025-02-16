import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/profile_button.dart';
import '../widgets/top_navbar.dart';

class ManageAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? addressData;

  const ManageAddressScreen({super.key, this.addressData});

  @override
  _ManageAddressScreenState createState() => _ManageAddressScreenState();
}

class _ManageAddressScreenState extends State<ManageAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _streetController;
  late TextEditingController _zipcodeController;

  @override
  void initState() {
    super.initState();
    _countryController = TextEditingController(text: widget.addressData?['country'] ?? '');
    _cityController = TextEditingController(text: widget.addressData?['city'] ?? '');
    _streetController = TextEditingController(text: widget.addressData?['street'] ?? '');
    _zipcodeController = TextEditingController(text: widget.addressData?['zipcode'] ?? '');
  }

  String _trimText(String value) {
    return value.trim();
  }

  void _saveAddressInfo() async {
    if (_formKey.currentState!.validate()) {
      final authService = AuthService();
      final token = await authService.getToken();

      if (token != null) {
        final updatedAddress = {
          'country': _trimText(_countryController.text),
          'city': _trimText(_cityController.text),
          'street': _trimText(_streetController.text),
          'zipcode': _trimText(_zipcodeController.text),
        };

        try {
          final response = await ApiService().updateBillingAddress(token, updatedAddress);
          Navigator.pop(context, response.data['address']);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save address info: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: const TopNavbar(title: 'Manage Address', backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _countryController,
                label: 'Country',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Country is required';
                  }
                  if (value.length > 100) {
                    return 'Country must be at most 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _cityController,
                label: 'City',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'City is required';
                  }
                  if (value.length > 100) {
                    return 'City must be at most 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _streetController,
                label: 'Street',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Street is required';
                  }
                  if (value.length > 255) {
                    return 'Street must be at most 255 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _zipcodeController,
                label: 'Zip Code',
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Zip Code is required';
                  if (!RegExp(r'^[0-9A-Za-z-]+$').hasMatch(value)) {
                    return 'Enter a valid Zip Code';
                  }
                  if (value.length > 20) {
                    return 'Zip Code must be at most 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Buttons: Cancel & Save
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 190,
                    child: ProfileButton(
                      icon: Icons.save_alt_rounded,
                      label: 'Save Changes',
                      onTap: _saveAddressInfo,
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
