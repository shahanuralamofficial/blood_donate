import 'package:firebase_auth/firebase_auth.dart'; // Add this
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/language_provider.dart';
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

    return Drawer(
      child: Column(
        children: [
          userAsync.when(
            data: (user) => UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: user?.profileImageUrl != null
                    ? NetworkImage(user!.profileImageUrl!)
                    : null,
                child: user?.profileImageUrl == null
                    ? const Icon(Icons.person, size: 40, color: Colors.red)
                    : null,
              ),
              accountName: Text(
                user?.name ?? 'User',
                style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(user?.phone ?? ''),
            ),
            loading: () => const DrawerHeader(child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const DrawerHeader(child: Icon(Icons.error)),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.person_outline,
            title: ref.tr('profile'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalProfileScreen())),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.history,
            title: ref.tr('history'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.favorite_border,
            title: ref.tr('saved_donors'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedDonorsScreen())),
          ),
          const Divider(),
          // New Features
          _buildDrawerItem(
            context,
            icon: Icons.medical_services_outlined,
            title: 'Doctors',
            subtitle: 'Coming Soon',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Doctors feature is coming soon!')),
              );
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.camera_alt_outlined,
            title: 'Prescription Reader',
            subtitle: 'AI Powered',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrescriptionReaderScreen())),
          ),
          const Spacer(),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: ref.tr('logout'),
            textColor: Colors.red,
            onTap: () => FirebaseAuth.instance.signOut(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.black87),
      title: Text(
        title,
        style: GoogleFonts.notoSansBengali(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.blue))
          : null,
      onTap: () {
        Navigator.pop(context); // Close drawer
        onTap();
      },
    );
  }
}
