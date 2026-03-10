import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../history/history_screen.dart';
import '../donors/donor_list_screen.dart';
import '../requests/request_list_screen.dart';
import '../../providers/language_provider.dart';
import '../profile/personal_profile_screen.dart';
import '../donors/saved_donors_screen.dart';
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
              ref.tr('congratulations'),
              style: GoogleFonts.notoSansBengali(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ref.tr('rank_update_message'),
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
                '${ref.tr('rank')}: $rank',
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
            child: Text(ref.tr('ok')),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("URL Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserDataProvider);

    ref.listen(currentUserDataProvider, (previous, next) {
      final user = next.value;
      if (user == null) return;

      if (user.rankUpdatePending && !_celebrationShown) {
        _celebrationShown = true;
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'rankUpdatePending': false,
        });
        _showCelebrationDialog(user.rank);
      }

      if ((user.bloodGroup == null || user.address == null) && !_profileAlertShown) {
        _profileAlertShown = true;
      }
    });

    return Scaffold(
      drawer: _buildDrawer(context, userAsync.value),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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

  Widget _buildDrawer(BuildContext context, dynamic user) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          _buildDrawerHeader(user),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildDrawerSectionTitle(ref.tr('general')),
                  _buildDrawerItem(
                    icon: Icons.language_rounded,
                    title: ref.tr('language'),
                    color: Colors.purple.shade700,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ref.watch(languageProvider).languageCode == 'bn' ? 'বাংলা' : 'English',
                        style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12),
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
                  _buildDrawerItem(
                    icon: Icons.settings_suggest_rounded,
                    title: ref.tr('settings_profile'),
                    color: Colors.blue.shade700,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalProfileScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.favorite_rounded,
                    title: ref.tr('saved_donors'),
                    color: Colors.red.shade600,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedDonorsScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.history_rounded,
                    title: ref.tr('activity_history'),
                    color: Colors.orange.shade700,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 3);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(thickness: 0.5),
                  ),
                  _buildDrawerSectionTitle(ref.tr('others')),
                  _buildDrawerItem(
                    icon: Icons.local_hospital_rounded,
                    title: ref.tr('hospitals'),
                    subtitle: ref.tr('coming_soon'),
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.tr('coming_soon_msg'))));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.headset_mic_rounded,
                    title: ref.tr('support_feedback'),
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(context);
                      _showSupportDialog();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: ref.tr('about_us'),
                    color: Colors.grey.shade700,
                    onTap: () { 
                      Navigator.pop(context);
                      _showAboutDialog();
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildDrawerFooter(),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(ref.tr('about_us'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.red,
              child: Icon(Icons.bloodtype, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'রক্তদান - Blood Donate',
              style: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'এটি একটি সম্পূর্ণ অলাভজনক প্ল্যাটফর্ম যার লক্ষ্য জরুরি প্রয়োজনে রক্তদাতার সন্ধান সহজ করা।',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansBengali(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            _buildSupportOption(
              icon: Icons.facebook_rounded,
              title: 'Facebook Page',
              subtitle: 'আমাদের ফেসবুক পেজে যুক্ত হন',
              color: const Color(0xFF1877F2),
              onTap: () => _launchUrl('https://www.facebook.com/blooddonate'),
            ),
            const SizedBox(height: 12),
            _buildSupportOption(
              icon: Icons.telegram_rounded,
              title: 'Telegram Channel',
              subtitle: 'লেটেস্ট আপডেট পেতে জয়েন করুন',
              color: const Color(0xFF0088cc),
              onTap: () => _launchUrl('https://t.me/blood_donatebd'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.tr('close'), style: GoogleFonts.notoSansBengali()),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(dynamic user) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalProfileScreen()));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
        decoration: const BoxDecoration(
          color: Color(0xFFB71C1C),
          image: DecorationImage(
            image: NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'),
            opacity: 0.1,
            repeat: ImageRepeat.repeat,
          ),
          borderRadius: BorderRadius.only(bottomRight: Radius.circular(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 38,
                backgroundColor: Colors.grey.shade100,
                backgroundImage: user?.profileImageUrl != null ? NetworkImage(user!.profileImageUrl!) : null,
                child: user?.profileImageUrl == null ? const Icon(Icons.person, size: 45, color: Color(0xFFE53935)) : null,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              user?.name ?? ref.tr('guest'),
              style: GoogleFonts.notoSansBengali(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bloodtype, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${ref.tr('group')}: ${user?.bloodGroup ?? ref.tr('not_available')}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (user?.rank != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          ref.tr('rank_${user!.rank.toLowerCase()}').toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 12),
      child: Text(
        title,
        style: GoogleFonts.notoSansBengali(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.notoSansBengali(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade900),
        ),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.red, fontSize: 11)) : null,
        trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Blood Donate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFB71C1C))),
              Text('Version 1.0.0', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
          IconButton(
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Text(ref.tr('logout'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
                  content: Text(ref.tr('confirm_logout'), style: GoogleFonts.notoSansBengali()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(ref.tr('no'), style: GoogleFonts.notoSansBengali(color: Colors.grey.shade600)),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(ref.tr('yes'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              }
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.grey),
            tooltip: ref.tr('logout'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        title: Text(ref.tr('support_feedback'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ref.tr('support_message'),
              style: GoogleFonts.notoSansBengali(fontSize: 14, color: Colors.blueGrey.shade700),
            ),
            const SizedBox(height: 24),
            _buildSupportOption(
              icon: Icons.facebook_rounded,
              title: ref.tr('facebook_page'),
              subtitle: ref.tr('facebook_community'),
              color: const Color(0xFF1877F2),
              onTap: () {
                Navigator.pop(context);
                _launchUrl('https://www.facebook.com/blooddonate');
              },
            ),
            const SizedBox(height: 12),
            _buildSupportOption(
              icon: Icons.telegram_rounded,
              title: ref.tr('telegram_support'),
              subtitle: ref.tr('telegram_subtitle'),
              color: const Color(0xFF0088cc),
              onTap: () {
                Navigator.pop(context);
                _launchUrl('https://t.me/blood_donatebd');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.tr('cancel'), style: GoogleFonts.notoSansBengali(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                  Text(subtitle, style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.blueGrey.shade600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
