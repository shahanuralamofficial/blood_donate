import 'package:blood_donate/presentation/providers/language_provider.dart';
import 'package:blood_donate/presentation/screens/history/history_screen.dart';
import 'package:blood_donate/presentation/screens/home/home_screen.dart';
import 'package:blood_donate/presentation/screens/profile/personal_profile_screen.dart';
import 'package:blood_donate/presentation/screens/requests/request_list_screen.dart';
import 'package:blood_donate/presentation/screens/donors/donor_list_screen.dart';
import 'package:blood_donate/presentation/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:blood_donate/presentation/providers/auth_provider.dart';

class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const RequestListScreen(),
    const DonorListScreen(),
    const HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
  }

  // Removed redundant _checkProfileIncomplete from here as it's handled in HomeScreen

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: const Color(0xFFB71C1C),
              unselectedItemColor: Colors.grey.shade400,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              elevation: 0,
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: ref.tr('home')),
                BottomNavigationBarItem(icon: const Icon(Icons.bloodtype_rounded), label: ref.tr('requests')),
                BottomNavigationBarItem(icon: const Icon(Icons.search_rounded), label: ref.tr('donors')),
                BottomNavigationBarItem(icon: const Icon(Icons.history_rounded), label: ref.tr('history')),
              ],
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
    );
  }
}
