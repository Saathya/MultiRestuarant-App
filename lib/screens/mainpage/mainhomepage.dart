import 'package:flutter/material.dart';
import 'package:multi_restaurant_app/screens/booking/booking.dart';
import 'package:multi_restaurant_app/screens/home.dart';
import 'package:multi_restaurant_app/screens/profile/profilepage.dart';
import 'package:multi_restaurant_app/show_nearby.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const MapScreen(),
    const BookingListScreen(),
    const ShowNearbyRestaurants(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomAppBar(
        height: 80,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavBarItem(Icons.home_filled, 'Home', 0),
              _buildNavBarItem(Icons.book, 'Booking', 1),
              _buildNavBarItem(Icons.restaurant, 'NearBY', 2),
              _buildNavBarItem(Icons.person, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, String label, int index) {
    return InkWell(
      onTap: () {
        _onItemTapped(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _selectedIndex == index ? Colors.red : Colors.black,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: _selectedIndex == index ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
