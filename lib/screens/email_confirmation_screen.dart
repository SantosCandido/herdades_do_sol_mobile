import 'package:flutter/material.dart';
import '../widgets/profile_button.dart';
import '../widgets/top_navbar.dart';

class EmailConfirmationScreen extends StatelessWidget {
  final String email;

  const EmailConfirmationScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: const TopNavbar(title: 'Email Confirmation', backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.mail_outline, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'Confirm your email',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'A confirmation email has been sent to:',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              email,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 70),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 170,
                  child: ProfileButton(
                    icon: Icons.home,
                    iconColor: Colors.orange,
                    label: 'HOMEPAGE',
                    textColor: Colors.orange,
                    fontWeight: FontWeight.bold,
                    onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                  ),
                ),
              ],
            ),
          ]
        ),
      ),
    );
  }
}
