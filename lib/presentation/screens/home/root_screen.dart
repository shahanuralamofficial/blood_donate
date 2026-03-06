import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../history/history_screen.dart';
import '../donors/donor_list_screen.dart';
import '../requests/request_list_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../home/notification_screen.dart';
import '../../providers/language_provider.dart';
import 'home_screen.dart';

class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  int _selectedIndex = 0;
  bool _celebrationShown = false;
  bool _profileAlertShown = false;

  final List<Widget> _screens = [
    const HomeScreen(),
    const RequestListScreen(),
    const DonorListScreen(),
    const HistoryScreen(),
  ];

  void _showCelebrationDialog(String rank) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.stars_rounded, color: Colors.amber, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'অভিনন্দন!',
              style: GoogleFonts.notoSansBengali(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'আপনার রক্তদান সফলভাবে সম্পন্ন হয়েছে ❤️',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'র‍্যাঙ্ক: $rank',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }

  void _showProfileCompleteDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_pin_rounded, color: Colors.blue, size: 30),
            SizedBox(width: 10),
            Text('প্রোফাইল অসম্পূর্ণ!'),
          ],
        ),
        content: const Text(
          'আপনার প্রোফাইলটি এখনও সম্পূর্ণ করা হয়নি। রক্ত দান বা গ্রহণ করার জন্য দয়া করে আপনার ব্লাড গ্রুপ এবং ঠিকানা আপডেট করুন।',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('পরে করব', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final user = ref.read(currentUserDataProvider).value;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(user: user),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('এখনই করুন'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // গ্লোবাল লিসেনার (র‍্যাঙ্ক এবং প্রোফাইল চেক)
    ref.listen(currentUserDataProvider, (previous, next) {
      final user = next.value;
      if (user == null) return;

      // ১. র‍্যাঙ্ক আপডেট পপআপ
      if (user.rankUpdatePending && !_celebrationShown) {
        _celebrationShown = true;
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'rankUpdatePending': false,
        });
        _showCelebrationDialog(user.rank);
      }

      // ২. প্রোফাইল কমপ্লিট পপআপ (যদি ব্লাড গ্রুপ বা ঠিকানা না থাকে)
      if ((user.bloodGroup == null || user.address == null) && !_profileAlertShown) {
        _profileAlertShown = true;
        // একটু দেরি করে দেখাচ্ছি যাতে হোম স্ক্রিন লোড হওয়ার পর আসে
        Future.delayed(const Duration(seconds: 2), () {
          _showProfileCompleteDialog();
        });
      }
    });

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFFE53935)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  ref.watch(currentUserDataProvider).value?.name[0].toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE53935)),
                ),
              ),
              accountName: Text(ref.watch(currentUserDataProvider).value?.name ?? 'User'),
              accountEmail: Text(ref.watch(currentUserDataProvider).value?.email ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.language_rounded, color: Colors.blue),
              title: Text(ref.tr('language')),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ref.watch(languageProvider).languageCode == 'bn' ? 'বাংলা' : 'English',
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  builder: (context) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ref.tr('language'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        ListTile(
                          leading: const Text('🇧🇩', style: TextStyle(fontSize: 24)),
                          title: const Text('বাংলা', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: ref.watch(languageProvider).languageCode == 'bn' 
                              ? const Icon(Icons.check_circle, color: Colors.green) 
                              : null,
                          onTap: () {
                            ref.read(languageProvider.notifier).changeLanguage('bn');
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                          title: const Text('English', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: ref.watch(languageProvider).languageCode == 'en' 
                              ? const Icon(Icons.check_circle, color: Colors.green) 
                              : null,
                          onTap: () {
                            ref.read(languageProvider.notifier).changeLanguage('en');
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_rounded, color: Colors.orange),
              title: Text(ref.tr('notifications')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: Text(ref.tr('logout')),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(ref.tr('logout')),
                    content: Text(ref.tr('confirm_logout')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(ref.tr('no'))),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pop(context);
                        },
                        child: Text(ref.tr('yes'), style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFFE53935),
              unselectedItemColor: Colors.grey.shade400,
              showSelectedLabels: true,
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
    );
  }
}
