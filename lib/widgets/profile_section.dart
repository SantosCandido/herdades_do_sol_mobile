import 'package:flutter/material.dart';
import 'profile_button.dart';

class ProfileSection extends StatelessWidget {
  final String title;
  final List<ProfileButton> buttons;

  const ProfileSection({
    super.key,
    required this.title,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        ...buttons,
        const Divider(color: Colors.grey),
      ],
    );
  }
}
