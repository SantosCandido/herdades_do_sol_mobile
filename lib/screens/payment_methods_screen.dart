import 'package:flutter/material.dart';
import 'package:herdades_do_sol/widgets/top_navbar.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/profile_button.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  _PaymentMethodsScreenState createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<dynamic> paymentMethods = [];
  bool isLoading = true;
  bool canAddMorePaymentMethods = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  void _loadPaymentMethods() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token != null) {
      try {
        final response = await ApiService().getPaymentMethods(token);
        setState(() {
          paymentMethods = response.data['payment_methods'] ?? [];
          isLoading = false;
          canAddMorePaymentMethods = paymentMethods.length < 5;
        });
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load payment methods: $e')),
        );
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  void _deletePaymentMethod(int id) async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token != null) {
      try {
        await ApiService().deletePaymentMethod(token, id);

        setState(() {
          paymentMethods.removeWhere((payment) => payment['id'] == id);
          canAddMorePaymentMethods = paymentMethods.length < 5;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment method deleted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete payment method: $e')),
        );
      }
    }
  }

  void _setDefaultPaymentMethod(int paymentId) async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token != null) {
      try {
        final response = await ApiService().setDefaultPaymentMethod(token, paymentId);
        if (response.statusCode == 200) {
          _loadPaymentMethods();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set default payment method: $e')),
        );
      }
    }
  }

  void _navigateToAddPaymentMethod() {
    Navigator.pushNamed(context, '/add_payment_method').then((value) {
      if (value != null) {
        _loadPaymentMethods();
      }
    });
  }

  IconData _getCardIcon(String type) {
    switch (type.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.payment;
      default:
        return Icons.credit_card_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: const TopNavbar(
        title: 'Payment Methods',
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : paymentMethods.isEmpty
          ? _buildEmptyState()
          : _buildPaymentMethodsList(),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.credit_card_off, size: 80, color: Colors.white),
          const SizedBox(height: 10),
          const Text(
            'No payment methods added',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _navigateToAddPaymentMethod,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Payment Method'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 20),
      itemCount: paymentMethods.length,
      itemBuilder: (context, index) {
        final payment = paymentMethods[index];
        String identifier = payment['identifier'] ?? 'Unnamed Card';
        String cardHolder = payment['name'] ?? 'Unknown Holder';
        String cardNumber = payment['last4'] ?? '****';
        String expiration = payment['validity'] ?? 'MM/YY';
        String cardType = (payment['type'] is Map) ? payment['type']['name'] ?? 'Unknown' : payment['type'] ?? 'Unknown';
        bool isPredefined = payment['predefined'] == 1;

        return Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100),
                    Icon(
                      _getCardIcon(cardType),
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            identifier,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),

                          Text(
                            cardHolder,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),

                          Text(
                            '**** **** **** $cardNumber',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Exp: $expiration',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white54,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 80),
                                child: Text(
                                  cardType,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                top: 8,
                right: 8,
                child: Switch(
                  value: isPredefined,
                  activeColor: Colors.orangeAccent,
                  onChanged: (bool newValue) {
                    _setDefaultPaymentMethod(payment['id']);
                  },
                ),
              ),

              Positioned(
                bottom: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePaymentMethod(payment['id']),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: paymentMethods.isNotEmpty
          ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Visibility(
            visible: canAddMorePaymentMethods,
            child: FloatingActionButton(
              onPressed: _navigateToAddPaymentMethod,
              backgroundColor: Colors.orange,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
          SizedBox(
            width: 135,
            child: ProfileButton(
              icon: Icons.arrow_back,
              label: 'Back',
              onTap: () => Navigator.pop(context),
            ),
          ),
        ],
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 135,
            child: ProfileButton(
              icon: Icons.arrow_back,
              label: 'Back',
              onTap: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
