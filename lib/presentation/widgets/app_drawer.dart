import 'package:blood_donate/presentation/providers/language_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../screens/profile/personal_profile_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/donors/saved_donors_screen.dart';
import '../screens/home/prescription_reader_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserDataProvider);
    final language = ref.watch(languageProvider);

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          userAsync.when(
            data: (user) => _buildHeader(context, user),
            loading: () => const DrawerHeader(child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const DrawerHeader(child: Icon(Icons.error)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildSectionTitle(ref.tr('general')),
                  _buildItem(
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
                        language.languageCode == 'bn' ? 'বাংলা' : 'English',
                        style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    onTap: () => _showLanguagePicker(context, ref),
                  ),
                  _buildItem(
                    icon: Icons.person_outline_rounded,
                    title: ref.tr('profile'),
                    color: Colors.blue.shade700,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalProfileScreen())),
                  ),
                  _buildItem(
                    icon: Icons.history_rounded,
                    title: ref.tr('history'),
                    color: Colors.orange.shade700,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                  ),
                  _buildItem(
                    icon: Icons.favorite_rounded,
                    title: ref.tr('saved_donors'),
                    color: Colors.red.shade600,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedDonorsScreen())),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  _buildSectionTitle(ref.tr('ai_health_features')),
                  _buildItem(
                    icon: Icons.camera_alt_rounded,
                    title: ref.tr('prescription_reader'),
                    subtitle: ref.tr('ai_powered_ocr'),
                    color: Colors.teal.shade600,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrescriptionReaderScreen())),
                  ),
                  _buildItem(
                    icon: Icons.local_hospital_rounded,
                    title: ref.tr('hospitals'),
                    subtitle: ref.tr('nearby_facilities'),
                    color: Colors.green.shade700,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ref.tr('coming_soon_msg'))),
                      );
                    },
                  ),
                  _buildItem(
                    icon: Icons.medical_services_rounded,
                    title: ref.tr('doctors_and_labs'),
                    subtitle: ref.tr('coming_soon'),
                    color: Colors.indigo.shade600,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ref.tr('coming_soon_msg'))),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildLogoutButton(ref),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
      decoration: const BoxDecoration(
        color: Color(0xFFE53935),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            backgroundImage: user?.profileImageUrl != null ? NetworkImage(user!.profileImageUrl!) : null,
            child: user?.profileImageUrl == null ? const Icon(Icons.person, size: 40, color: Color(0xFFE53935)) : null,
          ),
          const SizedBox(height: 15),
          Text(
            user?.name ?? 'Guest User',
            style: GoogleFonts.notoSansBengali(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            user?.phone ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: GoogleFonts.notoSansBengali(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)) : null,
      trailing: trailing,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: Colors.red),
        title: Text(ref.tr('logout'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        onTap: () => FirebaseAuth.instance.signOut(),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ref.tr('language'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Text('🇧🇩', style: TextStyle(fontSize: 24)),
              title: const Text('বাংলা', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                ref.read(languageProvider.notifier).changeLanguage('bn');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English', style: TextStyle(fontWeight: FontWeight.bold)),
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
  }
}

