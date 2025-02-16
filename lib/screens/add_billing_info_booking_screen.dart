import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/profile_button.dart';
import '../widgets/top_navbar.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AddBillingInfoBookingScreen extends StatefulWidget {
  final Map<String, dynamic>? billingInfo;

  const AddBillingInfoBookingScreen({super.key, this.billingInfo});

  @override
  _AddBillingInfoBookingScreenState createState() => _AddBillingInfoBookingScreenState();
}

class _AddBillingInfoBookingScreenState extends State<AddBillingInfoBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nifController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.billingInfo?['name'] ?? '');
    _nifController = TextEditingController(text: widget.billingInfo?['nif'] ?? '');
    _emailController = TextEditingController(text: widget.billingInfo?['email'] ?? '');
    _phoneController = TextEditingController(text: widget.billingInfo?['phone'] ?? '+');
  }

  String _trimName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _saveBillingInfo() async {
    if (_formKey.currentState!.validate()) {
      final billingData = {
        'name': _trimName(_nameController.text),
        'nif': _nifController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      final token = await AuthService().getToken();
      if (token != null) {
        try {
          final response = await ApiService().updateBillingInfo(token, billingData);
          Navigator.pop(context, response.data['billing']);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save billing info: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nifController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: const TopNavbar(title: 'Billing Information', backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Name is required';
                  if (value.length > 50) return 'Name must be at most 50 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _nifController,
                label: 'NIF',
                keyboardType: TextInputType.number,
                maxLength: 9,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'NIF is required';
                  if (value.length != 9) return 'NIF must be exactly 9 digits';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email is required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _phoneController,
                label: 'Phone',
                keyboardType: TextInputType.phone,
                maxLength: 15,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\+?\d*$')),
                  LengthLimitingTextInputFormatter(15),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Phone number is required';
                  if (!RegExp(r'^\+\d{8,14}$').hasMatch(value)) return 'Phone must start with "+" and be 8-14 digits';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 210,
                    child: ProfileButton(
                      icon: Icons.save_alt_rounded,
                      label: 'Save Billing Info',
                      onTap: _saveBillingInfo,
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
