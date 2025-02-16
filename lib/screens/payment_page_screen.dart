import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class PaymentPage extends StatefulWidget {
  final String selectedEstate;
  final String selectedEstateName;
  final String selectedAccommodation;
  final String selectedAccommodationName;
  final double accommodationPrice;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int selectedAdults;
  final int selectedChildren;
  final List<Map<String, dynamic>> selectedActivities;

  PaymentPage({
    super.key,
    required this.selectedEstate,
    required this.selectedEstateName,
    required this.selectedAccommodation,
    required this.selectedAccommodationName,
    required this.accommodationPrice,
    required String checkInDate,
    required String checkOutDate,
    required this.selectedAdults,
    required this.selectedChildren,
    required this.selectedActivities,
  })  : checkInDate = DateTime.parse(checkInDate),
        checkOutDate = DateTime.parse(checkOutDate);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  Map<String, dynamic>? billingInfo;
  Map<String, dynamic>? paymentMethod;

  @override
  void initState() {
    super.initState();
    _loadUserBillingAndPayment();
  }

  void _loadUserBillingAndPayment() async {
    final token = await AuthService().getToken();
    if (token != null) {
      try {
        final billingResponse = await ApiService().getBillingInfo(token);
        final defaultBilling = billingResponse.data['billing'] ?? null;

        final paymentResponse = await ApiService().getPaymentMethods(token);
        final methods = paymentResponse.data['payment_methods'] as List<dynamic>;
        final defaultPayment = methods.firstWhere(
              (p) => p['predefined'] == 1,
          orElse: () => null,
        );

        setState(() {
          billingInfo = defaultBilling;
          paymentMethod = defaultPayment;
        });
      } catch (e) {
        print("Error loading billing/payment info: $e");
      }
    }
  }

  double calculateTotalPrice() {
    int nights = widget.checkOutDate.difference(widget.checkInDate).inDays;
    if (nights < 1) nights = 1;
    double accommodationTotal = widget.accommodationPrice * nights;
    double activitiesTotal = widget.selectedActivities.fold(0.0, (total, activity) {
      return total + (activity['price'] as double);
    });
    return accommodationTotal + activitiesTotal;
  }

  void _navigateToAddPaymentMethod() async {
    final token = await AuthService().getToken();
    if (token == null) return;

    final response = await ApiService().getPaymentMethods(token);
    final methods = response.data['payment_methods'] as List<dynamic>? ?? [];

    if (methods.isEmpty) {
      final result = await Navigator.pushNamed(context, '/add_payment_method_booking');
      if (result != null) {
        setState(() {
          paymentMethod = result as Map<String, dynamic>;
        });
      }
    } else {
      final result = await Navigator.pushNamed(context, '/payment_methods_booking');

      if (result == true) {
        _loadUserBillingAndPayment();
      }
    }
  }

  void _navigateToAddBillingInfo() async {
    final result = await Navigator.pushNamed(
      context,
      '/add_billing_info_booking',
      arguments: billingInfo,
    );
    if (result != null) {
      setState(() {
        billingInfo = result as Map<String, dynamic>;
      });
    }
  }

  void _bookReservation() async {
    if (billingInfo == null || paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide billing information and a payment method.')),
      );
      return;
    }

    final token = await AuthService().getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Please log in again.')),
      );
      return;
    }

    final bookingData = {
      'estate_id': widget.selectedEstate,
      'accommodation_id': widget.selectedAccommodation,
      'entry_date': widget.checkInDate.toIso8601String(),
      'exit_date': widget.checkOutDate.toIso8601String(),
      'groupsize': widget.selectedAdults + widget.selectedChildren,
      'children': widget.selectedChildren,
      'price': calculateTotalPrice(),
      'billing_id': billingInfo!['id'],
      'payment_method_id': paymentMethod!['id'],
      'activities': widget.selectedActivities.map((activity) => activity['id']).toList(),
    };

    print('Sending booking data: $bookingData');

    try {
      final response = await ApiService().bookReservation(token, bookingData);
      print('Response data: ${response.data}');

      if (response.statusCode == 201) {
        Navigator.pushNamed(
          context,
          '/booking_confirmation',
          arguments: {
            'id': response.data['reservation_id'] ?? 'Unknown',
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: ${response.data}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    }
  }

  void _cancelPayment() {
    Navigator.popUntil(context, ModalRoute.withName('/home'));
  }

  Widget _buildInfoCard({required String title, required String content, required VoidCallback onTap}) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
        subtitle: Text(content, style: const TextStyle(color: Colors.white70)),
        trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: onTap),
      ),
    );
  }

  Widget _buildReservationCard() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.selectedEstateName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.selectedAdults + widget.selectedChildren} Guests',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Check-in: ${DateFormat('dd/MM/yyyy').format(widget.checkInDate)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  'Check-out: ${DateFormat('dd/MM/yyyy').format(widget.checkOutDate)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.selectedAccommodationName,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  '€${widget.accommodationPrice.toStringAsFixed(2)}/night',
                  style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesCard() {
    if (widget.selectedActivities.isEmpty) return const SizedBox.shrink();
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected Activities:',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...widget.selectedActivities.map((activity) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    activity['name'],
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    "€${(activity['price'] as double).toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    String paymentInfo = 'No payment method selected';
    if (paymentMethod != null) {
      String cardType = 'Card';
      if (paymentMethod!['type'] != null && paymentMethod!['type'] is Map) {
        cardType = paymentMethod!['type']['name'] ?? 'Card';
      } else {
        cardType = paymentMethod?['card_type'] ?? 'Card';
      }
      String identifier = paymentMethod?['identifier'] ?? '';
      String last4 = paymentMethod?['last4'] ?? 'xxxx';
      String validity = paymentMethod?['validity'] ?? 'xxxx';

      paymentInfo = (identifier.isNotEmpty ? '$identifier\n' : '') +
          '$cardType - xxxx xxxx xxxx $last4\nExpires: $validity';
    }

    String billingDisplay = 'No billing information provided';
    if (billingInfo != null) {
      List<String> parts = [];
      if (billingInfo!['name'] != null) parts.add(billingInfo!['name']);
      if (billingInfo!['nif'] != null) parts.add(billingInfo!['nif']);
      if (billingInfo!['email'] != null) parts.add(billingInfo!['email']);
      if (billingInfo!['phone'] != null) parts.add(billingInfo!['phone']);
      billingDisplay = parts.join('\n');
    }

    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Payment'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                title: 'Billing Information',
                content: billingDisplay,
                onTap: _navigateToAddBillingInfo,
              ),
              const SizedBox(height: 10),

              _buildInfoCard(
                title: 'Payment Method',
                content: paymentInfo,
                onTap: _navigateToAddPaymentMethod,
              ),
              const SizedBox(height: 10),

              _buildReservationCard(),
              const SizedBox(height: 10),

              _buildActivitiesCard(),
              const SizedBox(height: 10),

              Card(
                color: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: Text(
                      'Total: ${calculateTotalPrice().toStringAsFixed(2)}€',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _bookReservation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[900],
                      padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 12),
                    ),
                    child: const Text('Pay and Book', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const SizedBox(width: 20),

                  ElevatedButton(
                    onPressed: _cancelPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 16)),
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
