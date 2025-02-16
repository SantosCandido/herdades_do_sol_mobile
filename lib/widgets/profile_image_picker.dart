import 'package:flutter/material.dart';
import 'dart:io';

class ProfileImagePicker extends StatelessWidget {
  final File? selectedImage;
  final String? existingImageUrl;
  final VoidCallback onPickImage;

  const ProfileImagePicker({
    super.key,
    this.selectedImage,
    this.existingImageUrl,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPickImage,
      child: CircleAvatar(
        radius: 90,
        backgroundColor: Colors.grey[700],
        backgroundImage: selectedImage != null
            ? FileImage(selectedImage!) as ImageProvider
            : (existingImageUrl != null
            ? NetworkImage(existingImageUrl!)
            : const AssetImage('assets/icons/default_avatar.png') as ImageProvider),
      ),
    );
  }
}