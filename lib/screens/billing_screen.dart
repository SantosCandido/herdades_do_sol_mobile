import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/profile_button.dart';
import '../widgets/top_navbar.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  _BillingPageState createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  Map<String, dynamic> billingData = {};
  Map<String, dynamic> addressData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBillingInfo();
  }

  void _loadBillingInfo() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token != null) {
      try {
        final response = await ApiService().getBillingInfo(token);
        final responseData = response.data;

        setState(() {
          billingData = responseData['billing'] ?? {};
          addressData = responseData['address'] ?? {};
          isLoading = false;
        });
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load billing info: $e')),
        );
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  void _navigateToEditBilling() async {
    final updatedBilling = await Navigator.pushNamed(context, '/manage_billing', arguments: billingData);
    if (updatedBilling != null) {
      setState(() {
        billingData = updatedBilling as Map<String, dynamic>;
      });
    }
  }

  void _navigateToEditAddress() async {
    final updatedAddress = await Navigator.pushNamed(context, '/manage_address', arguments: addressData);

    if (updatedAddress != null) {
      setState(() {
        addressData = updatedAddress as Map<String, dynamic>;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: const TopNavbar(
        title: 'Billing Information',
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Billing Information Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(minWidth: 400),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Billing Information',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      billingData.isNotEmpty
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${billingData['name']}', style: const TextStyle(color: Colors.white)),
                          Text('NIF: ${billingData['nif'] ?? 'Not provided'}', style: const TextStyle(color: Colors.white)),
                          Text('Email: ${billingData['email']}', style: const TextStyle(color: Colors.white)),
                          Text('Phone: ${billingData['phone'] ?? 'Not provided'}', style: const TextStyle(color: Colors.white)),
                        ],
                      )
                          : const Text('No billing information available.', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: _navigateToEditBilling,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Address Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(minWidth: 400),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Billing Address',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      addressData.isNotEmpty
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Country: ${addressData['country']}', style: const TextStyle(color: Colors.white)),
                          Text('City: ${addressData['city']}', style: const TextStyle(color: Colors.white)),
                          Text('Street: ${addressData['street']}', style: const TextStyle(color: Colors.white)),
                          Text('Zip Code: ${addressData['zipcode']}', style: const TextStyle(color: Colors.white)),
                        ],
                      )
                          : const Text('No address available.', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: _navigateToEditAddress,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),

            // Back Button
            Padding(
              padding: const EdgeInsets.only(top: 20, right: 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 120,
                  height: 45,
                  child: ProfileButton(
                    icon: Icons.arrow_back,
                    label: 'Back',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}