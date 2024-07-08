import 'package:flutter/material.dart';
import 'package:multi_restaurant_app/screens/home.dart';
import 'package:multi_restaurant_app/screens/profile/profilepage.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  _MainHomePageState createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const MapScreen(),
    Container(),
    Container(),
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
              _buildNavBarItem(Icons.message_outlined, 'Chat', 1),
              _buildNavBarItem(Icons.account_balance_wallet, 'Wallet', 2),
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
            color: _selectedIndex == index
                ? const Color(0xff2A977D)
                : Colors.black,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: _selectedIndex == index
                  ? const Color(0xff2A977D)
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
