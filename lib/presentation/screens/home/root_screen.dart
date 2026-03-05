import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../history/history_screen.dart';
import '../donors/donor_list_screen.dart';
import '../requests/request_list_screen.dart';
import 'home_screen.dart';

class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  int _selectedIndex = 0;
  bool _celebrationShown = false;

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

  @override
  Widget build(BuildContext context) {
    // গ্লোবাল অভিনন্দন লিসেনার
    ref.listen(currentUserDataProvider, (previous, next) {
      final user = next.value;
      if (user != null && user.rankUpdatePending && !_celebrationShown) {
        _celebrationShown = true;
        // ডাটাবেসে আপডেট করে দিচ্ছি যাতে পুনরায় না আসে
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'rankUpdatePending': false,
        });
        
        // পপআপ দেখাচ্ছি
        _showCelebrationDialog(user.rank);
        
        // কিছু সময় পর ফ্ল্যাগ রিসেট করছি যাতে ভবিষ্যতে আবার আসতে পারে
        Future.delayed(const Duration(minutes: 1), () {
          _celebrationShown = false;
        });
      }
    });

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
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'হোম'),
                BottomNavigationBarItem(icon: Icon(Icons.bloodtype_rounded), label: 'আবেদনকারী'),
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
