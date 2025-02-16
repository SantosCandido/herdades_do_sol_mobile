import 'package:flutter/material.dart';

class ProfileButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final double? width;
  final FontWeight? fontWeight;

  const ProfileButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
    this.width,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: fontWeight,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
