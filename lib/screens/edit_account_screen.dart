import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/profile_image_picker.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/profile_button.dart';
import '../widgets/top_navbar.dart';

class EditAccountPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditAccountPage({super.key, required this.userData});

  @override
  _EditAccountPageState createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _nifController;
  late TextEditingController _birthdateController;
  late TextEditingController _phoneController;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _firstnameController = TextEditingController(text: widget.userData['firstname']);
    _lastnameController = TextEditingController(text: widget.userData['lastname']);
    _nifController = TextEditingController(text: widget.userData['nif']?.toString() ?? '');
    _birthdateController = TextEditingController(text: widget.userData['birthdate']?.split('T')[0] ?? '');
    _phoneController = TextEditingController(
      text: widget.userData['phone']?.toString().startsWith('+') ?? false
          ? widget.userData['phone']
          : '+',
    );
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final apiService = ApiService();
      final authService = AuthService();

      final updatedUser = {
        'firstname': _firstnameController.text.trim(),
        'lastname': _lastnameController.text.trim(),
        'nif': _nifController.text.trim(),
        'birthdate': _birthdateController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      final token = await authService.getToken();
      if (token != null) {
        try {
          final response = await apiService.editUser(token, updatedUser, _selectedImage);

          if (response.statusCode == 200) {
            final updatedUserData = response.data['user'];

            if (updatedUserData['img'] != null) {
              updatedUserData['img'] = '${updatedUserData['img']}?t=${DateTime.now().millisecondsSinceEpoch}';
            }

            await authService.saveUserData(updatedUserData);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User updated successfully!')),
            );

            Navigator.pop(context, updatedUserData);
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update user: $e')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not authenticated')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      extendBody: true,
      appBar: const TopNavbar(
        title: 'Edit Account',
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              ProfileImagePicker(
                selectedImage: _selectedImage,
                existingImageUrl: _selectedImage != null
                    ? _selectedImage!.path
                    : widget.userData['img'] != null && widget.userData['img'].isNotEmpty
                    ? '${widget.userData['img']}?t=${DateTime.now().millisecondsSinceEpoch}'
                    : null,
                onPickImage: _pickImage,
              ),
              const SizedBox(height: 40),

              CustomTextField(
                controller: _firstnameController,
                label: 'First Name',
                hintText: 'Insert your first name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'First Name is required';
                  if (value.length < 3) return 'First Name must have at least 3 characters';
                  if (value.length > 11) return 'First Name must not exceed 11 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _lastnameController,
                label: 'Last Name',
                hintText: 'Insert your last name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Last Name is required';
                  if (value.length < 3) return 'Last Name must have at least 3 characters';
                  if (value.length > 11) return 'Last Name must not exceed 11 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 16),

              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Birthdate',
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _birthdateController.text.isEmpty ? 'Select your birthdate' : _birthdateController.text,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 190,
                    child: ProfileButton(
                      icon: Icons.save_alt_rounded,
                      label: 'Save Changes',
                      onTap: _saveChanges,
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
