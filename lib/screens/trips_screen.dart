import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/top_navbar.dart';
import '../widgets/bottom_navbar.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  _TripsScreenState createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  List<dynamic> trips = [];
  bool isLoading = true;
  bool isAuthenticated = false;
  String? userImageUrl;
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadUserData();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/estates');
    } else if (index == 4) {
      Navigator.pushNamed(context, '/user');
    }
  }

  Future<void> _checkAuthentication() async {
    final token = await AuthService().getToken();
    if (token != null) {
      setState(() {
        isAuthenticated = true;
      });
      _fetchTrips(token);
    } else {
      setState(() {
        isAuthenticated = false;
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    final isAuthenticated = await authService.isAuthenticated();
    if (!isAuthenticated) {
      setState(() {
        userImageUrl = null;
      });
      return;
    }
    final userData = await authService.getUserData();
    setState(() {
      userImageUrl = userData != null && userData['img'] != null
          ? '${userData['img']}?t=${DateTime.now().millisecondsSinceEpoch}'
          : 'assets/icons/default_avatar.png';
    });
  }

  Future<void> _fetchTrips(String token) async {
    try {
      final response = await ApiService().getTrips(token);
      setState(() {
        trips = response.data['trips'] ?? [];
        isLoading = false;
      });
      print("Trips data: ${response.data['trips']}");
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load trips: $e')));
    }
  }

  String formattedPrice(dynamic price) {
    try {
      double parsedPrice = double.tryParse(price.toString()) ?? 0.0;
      return '${parsedPrice.toStringAsFixed(2)}€';
    } catch (e) {
      return '0.00€';
    }
  }

  String getAccommodationImageUrl(String? imagePath) {
    const String storageBaseUrl =
        "http://10.0.2.2:8000/storage/accommodation_type/";

    if (imagePath == null || imagePath.isEmpty) {
      return 'https://via.placeholder.com/80';
    }

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    if (imagePath.startsWith('/')) {
      imagePath = imagePath.substring(1);
    }

    if (imagePath.startsWith('accommodation_type/')) {
      imagePath = imagePath.replaceFirst('accommodation_type/', '');
    }
    return '$storageBaseUrl$imagePath';
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final estate = trip['estate'] ?? {};
    final accommodation = trip['accommodation'] ?? {};
    final accommodationType = accommodation['accommodation_type'] ?? {};
    final activities = trip['activities'] ?? [];

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    getAccommodationImageUrl(accommodationType['img']),
                    width: 120,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey,
                        child: const Icon(Icons.image, color: Colors.white),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    estate['name'] ?? 'Unknown Estate',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const Text(
                  'Accommodation: ',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                  ),
                ),

                Text(
                  ' ${accommodation['name'] ?? 'Unknown'}',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ]
            ),

            const SizedBox(height: 10),

            Row(
                children: [
                  const Text(
                    'Check-in: ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    ),
                  ),

                  Text(
                    '${trip['entry_date']} ',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),

                  const Text(
                    ' Check-out: ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    ),
                  ),

                  Text(
                    '${trip['exit_date']}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ]
            ),

            if (activities.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  const Text(
                    'Activities:',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  ...activities.map((activity) => Text(
                    '• ${activity['name']}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  )),
                ],
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total Paid: ${formattedPrice(trip['price'])}',
                  style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ]
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: TopNavbar(
        title: 'My Trips',
        backgroundColor: Colors.black54,
        actions: [
          if (userImageUrl != null)
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {},
            ),
        ],
        userImageUrl: userImageUrl,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : !isAuthenticated
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Please log in to view your trips.',
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),

            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                    horizontal: 70, vertical: 8),
              ),
              child: const Text(
                'Log in',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      )
          : trips.isEmpty
          ? const Center(
        child: Text(
          'No trips found.',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          return _buildTripCard(trips[index]);
        },
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
