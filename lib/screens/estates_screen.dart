import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/top_navbar.dart';

class EstatesScreen extends StatefulWidget {
  const EstatesScreen({Key? key}) : super(key: key);

  @override
  _EstatesScreenState createState() => _EstatesScreenState();
}

class _EstatesScreenState extends State<EstatesScreen> {
  List<dynamic> accommodationTypes = [];
  List<dynamic> activities = [];
  bool isLoading = true;
  String? userImageUrl;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUserData();
  }

  void _onItemTapped(int index) {
    if (index != 4) {
      setState(() {
        _selectedIndex = index;
      });
      if (index == 0) {
        Navigator.pushNamed(context, '/home');
      } else if (index == 3) {
        Navigator.pushNamed(context, '/trips');
      }
    } else {
      Navigator.pushNamed(context, '/user');
    }
  }

  Future<void> _loadData() async {
    final apiService = ApiService();
    try {
      final fetchedAccommodationTypes = await apiService.getAccommodationTypes();
      final fetchedActivities = await apiService.getActivities();

      if (mounted) {
        setState(() {
          accommodationTypes = fetchedAccommodationTypes ?? [];
          activities = fetchedActivities ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      debugPrint('Error fetching data: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
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

  String getActivityImageUrl(String? imagePath) {
    const String storageBaseUrl = "http://10.0.2.2:8000/storage/activities/";
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    if (imagePath.startsWith('/')) {
      imagePath = imagePath.substring(1);
    }
    if (imagePath.startsWith('activities/')) {
      imagePath = imagePath.replaceFirst('activities/', '');
    }
    final url = '$storageBaseUrl$imagePath';
    return url;
  }

  String getAccommodationImageUrl(String? imagePath) {

    const String storageBaseUrl = "http://10.0.2.2:8000/storage/accommodation_type/";
    if (imagePath == null || imagePath.isEmpty) {
      return '';
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
    final url = '$storageBaseUrl$imagePath';
    return url;
  }

  Widget _buildListCard(Map<String, dynamic> item) {
    final imageUrl = getAccommodationImageUrl(item['img']);
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 150,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const SizedBox(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  item['description'] ?? 'No description available',
                  style: const TextStyle(color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> item) {
    final imageUrl = getActivityImageUrl(item['img']);
    final String? price =
    item['price'] != null ? '${item['price']}€' : null;

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 150,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const SizedBox(),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item['description'] ?? 'No description available',
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (price != null)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        price,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: TopNavbar(
        title: 'Estates',
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
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (accommodationTypes.isEmpty && activities.isEmpty)
              const Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            if (accommodationTypes.isNotEmpty) ...[
              const Text(
                'Accommodation Types',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: accommodationTypes.length,
                itemBuilder: (context, index) {
                  return _buildListCard(accommodationTypes[index]);
                },
              ),
              const SizedBox(height: 20),
            ],
            if (activities.isNotEmpty) ...[
              const Text(
                'Activities',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.7,
                ),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  return _buildGridCard(activities[index]);
                },
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
