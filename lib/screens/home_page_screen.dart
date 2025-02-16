import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/top_navbar.dart';
import '../widgets/bottom_navbar.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> estates = [];
  List<dynamic> availableAccommodationTypes = [];
  List<dynamic> availableAccommodations = [];
  List<dynamic> activities = [];

  List<String> selectedActivities = [];

  String? selectedEstate;
  String? selectedAccommodationType;
  String? selectedAccommodation;
  DateTime? checkInDate;
  DateTime? checkOutDate;
  int selectedAdults = 2;
  int selectedChildren = 0;

  bool isLoading = true;
  bool showAccommodations = false;
  bool showActivities = false;

  String? userImageUrl;
  int _selectedIndex = 0;

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
      if (index == 1) {
        Navigator.pushNamed(context, '/estates');
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
      final fetchedEstates = await apiService.getEstates();
      if (fetchedEstates.isNotEmpty) {
        setState(() {
          estates = fetchedEstates;
          selectedEstate = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    }
  }

  void _loadAccommodations() async {
    if (selectedAccommodationType == null) return;

    setState(() {
      selectedAccommodation = null;
      availableAccommodations = [];
    });

    final apiService = ApiService();
    final fetchedAccommodations = await apiService.getAvailableAccommodations(
      selectedEstate!,
      DateFormat('yyyy-MM-dd').format(checkInDate!),
      DateFormat('yyyy-MM-dd').format(checkOutDate!),
      selectedAdults + selectedChildren,
      selectedAccommodationType!,
    );

    setState(() {
      availableAccommodations = fetchedAccommodations;
    });
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

  double _calculateTotalPrice() {
    if (checkInDate == null || checkOutDate == null || selectedAccommodation == null)
      return 0.0;

    int nights = checkOutDate!.difference(checkInDate!).inDays;
    if (nights < 1) nights = 1;

    final accommodationObj = availableAccommodations.firstWhere(
          (a) => a['id'].toString() == selectedAccommodation,
      orElse: () => null,
    );
    if (accommodationObj == null) return 0.0;

    double accommodationPrice = double.tryParse(accommodationObj['price'].toString()) ?? 0.0;
    double totalAccommodation = accommodationPrice * nights;

    double totalActivities = 0.0;
    for (var actId in selectedActivities) {
      final act = activities.firstWhere(
            (act) => act['id'].toString() == actId,
        orElse: () => null,
      );
      if (act != null) {
        totalActivities += double.tryParse(act['price'].toString()) ?? 0.0;
      }
    }
    return totalAccommodation + totalActivities;
  }

  void _proceedToPayment() async {
    final authService = AuthService();
    final isAuthenticated = await authService.isAuthenticated();
    if (!isAuthenticated) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    final estateObj = estates.firstWhere((e) => e['id'].toString() == selectedEstate);
    final accommodationObj = availableAccommodations.firstWhere(
            (a) => a['id'].toString() == selectedAccommodation);
    final selectedActivitiesObjs = selectedActivities.map((id) {
      return activities.firstWhere((act) => act['id'].toString() == id);
    }).toList();

    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'selectedEstate': selectedEstate!,
        'selectedEstateName': estateObj['name'],
        'selectedAccommodation': selectedAccommodation!,
        'selectedAccommodationName': accommodationObj['name'],
        'accommodationPrice': accommodationObj['price'],
        'checkInDate': checkInDate!.toIso8601String(),
        'checkOutDate': checkOutDate!.toIso8601String(),
        'selectedAdults': selectedAdults,
        'selectedChildren': selectedChildren,
        'selectedActivities': selectedActivitiesObjs.map<Map<String, dynamic>>((act) {
          return {
            'id': int.parse(act['id'].toString()),
            'name': act['name'],
            'price': double.parse(act['price'].toString()),
          };
        }).toList(),
      },
    );
  }

  void _searchAvailability() async {
    if (selectedEstate == null || checkInDate == null || checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select estate and dates')),
      );
      return;
    }
    setState(() {
      isLoading = true;
      selectedAccommodationType = null;
      selectedAccommodation = null;
      availableAccommodationTypes = [];
      availableAccommodations = [];
      selectedActivities.clear();
    });
    final apiService = ApiService();
    try {
      final String formattedCheckInDate =
      DateFormat('yyyy-MM-dd').format(checkInDate!);
      final String formattedCheckOutDate =
      DateFormat('yyyy-MM-dd').format(checkOutDate!);

      final fetchedAccommodationTypes =
      await apiService.getAvailableAccommodationTypes(
        selectedEstate!,
        formattedCheckInDate,
        formattedCheckOutDate,
        selectedAdults + selectedChildren,
      );

      final fetchedActivities = await apiService.getActivitiesByEstateAndDate(
        selectedEstate!,
        formattedCheckInDate,
        formattedCheckOutDate,
        selectedAdults + selectedChildren,
        selectedChildren,
      );

      setState(() {
        availableAccommodationTypes = (fetchedAccommodationTypes is List)
            ? fetchedAccommodationTypes.map<Map<String, dynamic>>((item) {
          return {
            'accommodation_type_id': item['accommodation_type_id'] is int
                ? item['accommodation_type_id']
                : int.tryParse(item['accommodation_type_id'].toString()) ??
                0,
            'name': item['name'] ?? 'Unknown',
            'count': item['count'] is int
                ? item['count']
                : int.tryParse(item['count'].toString()) ?? 0,
          };
        }).toList()
            : [];
        activities = fetchedActivities;
        showActivities = fetchedActivities.isNotEmpty;
        showAccommodations = availableAccommodationTypes.isNotEmpty;
        isLoading = false;
      });

      if (availableAccommodationTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
              Text('No available accommodations for selected dates.')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    }
  }

  Future<void> _selectDate({required bool isCheckIn}) async {
    DateTime initialDate =
    isCheckIn ? DateTime.now() : checkInDate ?? DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() {
        if (isCheckIn) {
          checkInDate = pickedDate;
          checkOutDate = null;
        } else {
          checkOutDate = pickedDate;
        }
      });
    }
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _selectDate(isCheckIn: true),
            icon: const Icon(Icons.calendar_today),
            label: Text(checkInDate != null
                ? DateFormat('dd/MM/yyyy').format(checkInDate!)
                : 'Check-In'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _selectDate(isCheckIn: false),
            icon: const Icon(Icons.calendar_today),
            label: Text(checkOutDate != null
                ? DateFormat('dd/MM/yyyy').format(checkOutDate!)
                : 'Check-Out'),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Guests',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildGuestCounter('Adults', selectedAdults, (newValue) {
              setState(() {
                selectedAdults = newValue < 0 ? 0 : newValue;
              });
            }),
            _buildGuestCounter('Children', selectedChildren, (newValue) {
              setState(() {
                selectedChildren = newValue < 0 ? 0 : newValue;
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildGuestCounter(String label, int count, Function(int) onChanged) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.remove, color: Colors.white),
          onPressed: () => onChanged(count - 1),
        ),
        Text(count.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () => onChanged(count + 1),
        ),
      ],
    );
  }

  Widget _buildEstateDropdown() {
    return _buildDropdown(
      'Estate',
      estates,
      estates.any((item) => item['id'].toString() == selectedEstate)
          ? selectedEstate
          : null,
          (value) {
        setState(() {
          selectedEstate = value;
        });
      },
      hintText: 'Select an Estate',
    );
  }

  Widget _buildAccommodationTypesDropdown() {
    return _buildDropdown(
      'Accommodation Type',
      availableAccommodationTypes,
      availableAccommodationTypes.any((item) =>
      item['accommodation_type_id'].toString() ==
          selectedAccommodationType)
          ? selectedAccommodationType
          : null,
          (value) {
        setState(() {
          selectedAccommodationType = value;
          selectedAccommodation = null;
          availableAccommodations = [];
          _loadAccommodations();
        });
      },
      hintText: 'Select an Accommodation Type',
      idKey: 'accommodation_type_id',
      nameKey: 'name',
    );
  }

  Widget _buildAccommodationsDropdown() {
    List<Map<String, dynamic>> filteredAccommodations = [];
    for (var accommodation in availableAccommodations) {
      if (!filteredAccommodations.any((element) => element['name'] == accommodation['name'])) {
        filteredAccommodations.add(accommodation);
      }
    }
    return _buildDropdown(
      'Select Accommodation',
      filteredAccommodations,
      filteredAccommodations.any((item) => item['id'].toString() == selectedAccommodation)
          ? selectedAccommodation
          : null,
          (value) {
        setState(() {
          selectedAccommodation = value;
        });
      },
      hintText: 'Select an Accommodation',
    );
  }

  Widget _buildActivitiesDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Activities',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        GestureDetector(
          onTap: () {
            _showMultiSelectDialog();
          },
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
            child: Text(
              selectedActivities.isNotEmpty
                  ? selectedActivities.map((id) {
                final matchingActivity = activities.firstWhere(
                      (activity) => activity['id'].toString() == id,
                  orElse: () => null,
                );
                return matchingActivity != null ? matchingActivity['name'] : id;
              }).join(", ")
                  : "Select Activities",
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
      String label,
      List<dynamic> items,
      String? selectedValue,
      Function(String) onChanged, {
        String? hintText,
        String idKey = 'id',
        String nameKey = 'name',
      }) {
    List<Map<String, dynamic>> uniqueItems =
    items.map((item) => item as Map<String, dynamic>).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        DropdownButtonFormField<String>(
          value: uniqueItems.any((item) =>
          item[idKey].toString() == selectedValue)
              ? selectedValue
              : null,
          hint: hintText != null ? Text(hintText) : null,
          items: uniqueItems.map<DropdownMenuItem<String>>((item) {
            final itemId = item[idKey]?.toString() ?? '';
            final itemName = item[nameKey]?.toString() ?? 'Unknown';
            return DropdownMenuItem<String>(
              value: itemId,
              child:
              Text(itemName, style: const TextStyle(color: Colors.black)),
            );
          }).toList(),
          onChanged: (value) => onChanged(value ?? ''),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
        ),
      ],
    );
  }

  Future<void> _showMultiSelectDialog() async {
    List<String> tempSelected = List.from(selectedActivities);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select Activities"),
              content: SingleChildScrollView(
                child: Column(
                  children: activities.map((activity) {
                    bool isSelected = tempSelected.contains(activity['id'].toString());
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(
                          "${activity['name']} (${activity['date']} - ${activity['time']})"),
                      onChanged: (bool? checked) {
                        setStateDialog(() {
                          if (checked == true) {
                            if (!tempSelected.contains(activity['id'].toString())) {
                              tempSelected.add(activity['id'].toString());
                            }
                          } else {
                            tempSelected.remove(activity['id'].toString());
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, tempSelected);
                  },
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null) {
      setState(() {
        selectedActivities = result;
      });
    }
  }

  Widget _buildPlaceholder() {
    return Visibility(
      visible: !showAccommodations && !isLoading,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 80),
              Icon(Icons.search, size: 80, color: Colors.white70),
              SizedBox(height: 20),
              Text(
                'Select an estate and dates to check availability.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
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
        title: 'Booking Accommodation',
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildEstateDropdown(),
            const SizedBox(height: 20),
            _buildDateSelector(),
            const SizedBox(height: 40),
            _buildGuestSelector(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _searchAvailability,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Search Availability',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildPlaceholder(),
            if (availableAccommodationTypes.isNotEmpty)
              _buildAccommodationTypesDropdown(),
            const SizedBox(height: 20),

            if (selectedAccommodationType != null)
              _buildAccommodationsDropdown(),
            const SizedBox(height: 20),

            if (showActivities && selectedAccommodationType != null)
              _buildActivitiesDropdown(),
            const SizedBox(height: 40),

            Visibility(
              visible: selectedAccommodation != null,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _proceedToPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'Proceed to Payment',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Total: €${_calculateTotalPrice().toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
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