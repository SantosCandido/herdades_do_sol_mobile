import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/profile_button.dart';
import '../widgets/profile_section.dart';
import '../widgets/top_navbar.dart';
import '../widgets/bottom_navbar.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? userData;
  int _selectedIndex = 4;
  String? userImageUrl;

  bool hasUnreadNotifications = false;
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    }
    else if (index == 1) {
      Navigator.pushNamed(context, '/estates');
    }
    else if (index == 3) {
      Navigator.pushNamed(context, '/trips');
    }
  }

  void _loadUserData() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token != null) {
      try {
        final response = await ApiService().getUserData(token);

        if (response.statusCode == 401) {
          await _handleSessionExpired();
          return;
        }

        final newUserData = response.data['user'];

        setState(() {
          userData = newUserData;
          userImageUrl = (newUserData['img'] != null && newUserData['img'].startsWith('http'))
              ? '${newUserData['img']}?t=${DateTime.now().millisecondsSinceEpoch}'
              : 'assets/icons/default_avatar.png';
        });

      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch user data: $e')),
          );
        }
      }
    } else {
      await _handleSessionExpired();
    }
  }

  Future<void> _fetchNotifications() async {
    final token = await AuthService().getToken();
    if (token == null) return;

    try {
      final response = await ApiService().getNotifications(token);
      setState(() {
        notifications = response.data['notifications'] ?? [];
        hasUnreadNotifications = notifications.isNotEmpty;
      });
    } catch (e) {
      debugPrint("Failed to fetch notifications: $e");
    }
  }

  void _showNotifications() async {
    final token = await AuthService().getToken();
    if (token == null) return;

    try {
      await ApiService().markNotificationsAsRead(token);
      setState(() {
        hasUnreadNotifications = false;
      });

      _showNotificationDialog();
    } catch (e) {
      debugPrint("Failed to mark notifications as read: $e");
    }
  }

  void _showNotificationDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(color: Colors.white30),
              if (notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "No new notifications",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ...notifications.map((notification) => ListTile(
                title: Text(
                  notification['data']['title'],
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  notification['data']['message'],
                  style: const TextStyle(color: Colors.white70),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSessionExpired() async {
    final authService = AuthService();
    await authService.clearToken();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _navigateToPaymentMethods() async {
    final updatedPaymentMethods = await Navigator.pushNamed(context, '/payment_methods');

    if (updatedPaymentMethods != null) {
      setState(() {
      });
    }
  }

  void _navigateToBillingInfo() async {
    final updatedBilling = await Navigator.pushNamed(context, '/billing');

    if (updatedBilling != null) {
      setState(() {
        userData?['billing'] = updatedBilling;
      });
    }
  }

  void _navigateToEditAccount() async {
    final updatedUser = await Navigator.pushNamed(
      context,
      '/edit',
      arguments: userData,
    );

    if (updatedUser != null) {
      setState(() {
        userData = updatedUser as Map<String, dynamic>;
        userImageUrl = userData?['img'];
      });
    }
  }

  void _logout() async {
    await _authService.clearToken();
    setState(() {
      userData = null;
      userImageUrl = null;
    });
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: TopNavbar(
        title: 'User Profile',
        backgroundColor: Colors.black54,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: _showNotifications,
              ),
              if (hasUnreadNotifications)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: userImageUrl != null && userImageUrl!.startsWith('assets')
                        ? AssetImage(userImageUrl!) as ImageProvider
                        : userImageUrl != null
                        ? NetworkImage(userImageUrl!)
                        : const AssetImage('assets/icons/default_avatar.png'),
                    backgroundColor: Colors.grey[700],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${userData!['firstname']} ${userData!['lastname']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Genius Rewards Section
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You have a coupon!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '10% discount on your next reservation!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Payment Information Section
              ProfileSection(
                title: 'Payment Information',
                buttons: [
                  ProfileButton(
                    icon: Icons.payments_outlined,
                    label: 'Billing Preferences',
                    onTap: (_navigateToBillingInfo),
                  ),
                  ProfileButton(
                    icon: Icons.payment,
                    label: 'Payment Method',
                    onTap: (_navigateToPaymentMethods),
                  ),
                ],
              ),
              // Manage Account Section
              ProfileSection(
                title: 'Manage Account',
                buttons: [
                  ProfileButton(
                      icon: Icons.account_box_outlined,
                      label: 'Edit account',
                      onTap: (_navigateToEditAccount)
                  ),
                  ProfileButton(
                    icon: Icons.logout,
                    label: 'Log Out',
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    onTap: _logout,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}