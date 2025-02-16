import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/register_screen.dart';
import 'screens/email_confirmation_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_page_screen.dart';
import 'screens/payment_page_screen.dart';
import 'screens/add_billing_info_booking_screen.dart';
import 'screens/add_payment_method_booking_screen.dart';
import 'screens/payment_methods_booking_screen.dart';
import 'screens/booking_confirmation_screen.dart';
import 'screens/estates_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/user_screen.dart';
import 'screens/guest_user_screen.dart';
import 'screens/edit_account_screen.dart';
import 'screens/payment_methods_screen.dart';
import 'screens/add_payment_method_screen.dart';
import 'screens/billing_screen.dart';
import 'screens/manage_billing_screen.dart';
import 'screens/manage_address_screen.dart';

/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().clearToken();
  runApp(const MyApp());
}
*/

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      navigatorObservers: [routeObserver],
      routes: {
        '/': (context) => SplashScreen(),
        '/register': (context) => const RegisterScreen(),
        '/email_confirmation': (context) {
          final email = ModalRoute.of(context)!.settings.arguments as String;
          return EmailConfirmationScreen(email: email);
        },
        '/login': (context) => LoginScreen(),
        '/home': (context) => const HomePage(),
        '/payment': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PaymentPage(
            selectedEstate: args['selectedEstate'],
            selectedEstateName: args['selectedEstateName'],
            selectedAccommodation: args['selectedAccommodation'],
            selectedAccommodationName: args['selectedAccommodationName'],
            accommodationPrice: double.parse(args['accommodationPrice'].toString()),
            checkInDate: args['checkInDate'],
            checkOutDate: args['checkOutDate'],
            selectedAdults: args['selectedAdults'],
            selectedChildren: args['selectedChildren'],
            selectedActivities: args['selectedActivities'],
          );
        },
        '/add_billing_info_booking': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return AddBillingInfoBookingScreen(billingInfo: args);
        },
        '/payment_methods_booking': (context) => const PaymentMethodsBookingScreen(),
        '/add_payment_method_booking': (context) => const AddPaymentMethodBookingScreen(),
        '/booking_confirmation': (context) => const BookingConfirmationScreen(),
        '/estates': (context) => const EstatesScreen(),
        '/trips': (context) => const TripsScreen(),
        '/user': (context) {
          final authService = AuthService();
          return FutureBuilder<bool>(
            future: authService.isAuthenticated(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data == true) {
                return const UserPage();
              } else {
                return const GuestUserPage();
              }
            },
          );
        },
        '/edit': (context) {
          final userData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return EditAccountPage(userData: userData);
        },
        '/payment_methods': (context) => const PaymentMethodsScreen(),
        '/add_payment_method': (context) => const AddPaymentMethodScreen(),
        '/billing': (context) => const BillingPage(),
        '/manage_billing': (context) {
          final billingData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return ManageBillingScreen(billingData: billingData);
        },
        '/manage_address': (context) {
          final addressData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return ManageAddressScreen(addressData: addressData);
        },
      },
    );
  }
}