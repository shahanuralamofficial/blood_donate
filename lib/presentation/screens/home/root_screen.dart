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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileIncomplete();
    });
  }

  void _checkProfileIncomplete() {
    final userAsync = ref.read(currentUserDataProvider);
    userAsync.whenData((user) {
      if (user != null) {
        final isIncomplete = user.bloodGroup == null || 
                            user.bloodGroup!.isEmpty || 
                            user.address == null;
        
        if (isIncomplete) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(ref.tr('profile_incomplete'), style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Text(ref.tr('complete_profile_msg')),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalProfileScreen()));
                  },
                  child: Text(ref.tr('complete_now')),
                ),
              ],
            ),
          );
        }
      }
    });
  }

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

  void _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
