import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'email_confirmation_screen.dart';
import '../services/api_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/profile_button.dart';
import '../widgets/top_navbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(text: '+');
  final TextEditingController _nifController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark(),
          child: child!,
        );
      },
    );

    if (picked != null &&
        picked.isBefore(DateTime.now().subtract(const Duration(days: 6570)))) {
      setState(() {
        _birthdateController.text = picked.toIso8601String().split('T')[0];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be at least 18 years old')),
      );
    }
  }

  void _registerUser() async {
    if (_formKey.currentState!.validate()) {
      final apiService = ApiService();

      final userData = {
        'firstname': _firstnameController.text.trim(),
        'lastname': _lastnameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'password_confirmation': _passwordController.text.trim(),
        'nif': _nifController.text.trim(),
        'birthdate': _birthdateController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      try {
        final response = await apiService.registerUser(userData);

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailConfirmationScreen(
                email: _emailController.text.trim(),
              ),
            ),
          );
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 422) {
          final errors = e.response?.data['errors'];

          String errorMessage = 'Validation failed';
          if (errors != null) {
            errorMessage = errors.values.first[0];
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to register: ${e.message}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: const TopNavbar(title: 'Register', backgroundColor: Colors.orange),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Image(
                image: AssetImage('assets/icons/logo.png'),
                width: 140,
                height: 140,
              ),
              const SizedBox(height: 20),

              // Email Field
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email is required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password Field
              Row(
                children: [
                  Expanded(
                    child:CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: _obscurePassword ? Colors.grey : Colors.orange,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[\W]).{8,}$').hasMatch(value)) {
                          return 'Must be a strong password';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: _obscureConfirmPassword ? Colors.grey : Colors.orange,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // First Name & Last Name
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _firstnameController,
                      label: 'First Name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'First Name is required';
                        } else if (value.trim().length < 3) {
                          return 'Min 3 characters';
                        } else if (value.trim().length > 11) {
                          return 'Max 11 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      controller: _lastnameController,
                      label: 'Last Name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Last Name is required';
                        } else if (value.trim().length < 3) {
                          return 'Min 3 characters';
                        } else if (value.trim().length > 11) {
                          return 'Max 11 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Phone & NIF
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      keyboardType: TextInputType.phone,
                      maxLength: 15,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\+?\d*$')),
                        LengthLimitingTextInputFormatter(15),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Phone is required';
                        if (!RegExp(r'^\+\d{8,14}$').hasMatch(value)) {
                          return 'Phone must start with "+" and be 8-14 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
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
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Birthdate Field
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Birthdate',
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  child: Text(
                    _birthdateController.text.isEmpty ? 'Select your birthdate' : _birthdateController.text,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Buttons: Cancel & Register
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 190,
                    child: ProfileButton(
                      icon: Icons.app_registration,
                      label: 'Register',
                      onTap: _registerUser,
                    ),
                  ),
                  SizedBox(
                    width: 135,
                    child: ProfileButton(
                      icon: Icons.cancel,
                      label: 'Cancel',
                      onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Already have an account?
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text(
                  'Already have an account? Log in',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}