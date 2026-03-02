import 'package:flutter/material.dart';
import '../history/history_screen.dart';
import '../donors/donor_list_screen.dart';
import 'home_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DonorListScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFFE53935),
              unselectedItemColor: Colors.grey.shade400,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'হোম'),
                BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'দাতা'),
                BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'ইতিহাস'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
