import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:blood_donate/data/models/user_model.dart';
import '../../providers/donor_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/services/location_service.dart';
import '../chat/chat_screen.dart';
import 'donor_public_profile_screen.dart';

import '../../providers/language_provider.dart';

class DonorListScreen extends ConsumerStatefulWidget {
  const DonorListScreen({super.key});

  @override
  ConsumerState<DonorListScreen> createState() => _DonorListScreenState();
}

class _DonorListScreenState extends ConsumerState<DonorListScreen> {
  Position? _currentPosition;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      final pos = await LocationService().getCurrentPosition();
      setState(() => _currentPosition = pos);
    } catch (e) {
      debugPrint("Location Error: $e");
    }
  }

  double _calculateDistance(double endLat, double endLng) {
    if (_currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      endLat,
      endLng,
    ) / 1000;
  }

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Call Error: $e");
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!cleanPhone.startsWith('88')) {
      cleanPhone = '88$cleanPhone';
    }
    final Uri url = Uri.parse("https://wa.me/$cleanPhone");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("WhatsApp Error: $e");
    }
  }

  Future<void> _toggleSaveDonor(String donorId, List<String> currentlySaved) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    List<String> newList = List.from(currentlySaved);
    if (newList.contains(donorId)) {
      newList.remove(donorId);
    } else {
      newList.add(donorId);
    }

    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
      'savedDonors': newList,
    });
    ref.invalidate(currentUserDataProvider);
  }

  @override
  Widget build(BuildContext context) {
    final donorsAsync = ref.watch(availableDonorsProvider);
    final userData = ref.watch(currentUserDataProvider).value;
    final savedDonors = userData?.savedDonors ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(ref.tr('find_donor'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(availableDonorsProvider);
                ref.invalidate(currentUserDataProvider);
                await _determinePosition();
                await Future.delayed(const Duration(seconds: 1));
              },
              child: donorsAsync.when(
                data: (donors) {
                  final filteredDonors = donors.where((item) {
                    final isCurrentUser = item['user'].uid == userData?.uid;
                    if (isCurrentUser) return false;

                    final name = (item['user'].name ?? '').toString().toLowerCase();
                    final bg = (item['user'].bloodGroup ?? '').toString().toLowerCase();
                    final district = (item['user'].address?['district'] ?? '').toString().toLowerCase();
                    final thana = (item['user'].address?['thana'] ?? '').toString().toLowerCase();

                    return name.contains(_searchQuery) ||
                        bg.contains(_searchQuery) ||
                        district.contains(_searchQuery) ||
                        thana.contains(_searchQuery);
                  }).toList();

                  if (filteredDonors.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(ref.tr('no_donor_found'), style: GoogleFonts.notoSansBengali(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }

                  if (_currentPosition != null) {
                    filteredDonors.sort((a, b) {
                      final distA = _calculateDistance(a['donor'].location?.latitude ?? 0, a['donor'].location?.longitude ?? 0);
                      final distB = _calculateDistance(b['donor'].location?.latitude ?? 0, b['donor'].location?.longitude ?? 0);
                      return distA.compareTo(distB);
                    });
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filteredDonors.length,
                    itemBuilder: (context, index) {
                      final item = filteredDonors[index];
                      final user = item['user'];
                      final donor = item['donor'];
                      final distance = donor.location != null ? _calculateDistance(donor.location!.latitude, donor.location!.longitude) : null;
                      final isSaved = savedDonors.contains(user.uid);
                      final rating = user.averageRating;

                      return _buildDonorCard(user, donor, distance, isSaved, rating, userData, ref);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
                error: (e, s) => Center(child: Text('${ref.tr('error')}: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFE53935),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: ref.tr('search_hint'),
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      ),
    );
  }

  Widget _buildDonorCard(user, donor, distance, isSaved, rating, UserModel? userData, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DonorPublicProfileScreen(donor: user),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBloodGroupBadge(user.bloodGroup ?? '?', ref),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    user.name,
                                    style: GoogleFonts.notoSansBengali(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (user.uid != userData?.uid) {
                                      _toggleSaveDonor(
                                        user.uid,
                                        (ref.read(currentUserDataProvider).value?.savedDonors ?? []),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(ref.tr('cannot_save_self'))),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      user.uid == userData?.uid
                                          ? Icons.favorite_border
                                          : (isSaved ? Icons.favorite : Icons.favorite_border),
                                      color: user.uid == userData?.uid
                                          ? Colors.grey.shade300
                                          : Colors.orange,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${user.address?['thana'] ?? ref.tr('unknown')}, ${user.address?['district'] ?? ''}',
                                    style: GoogleFonts.notoSansBengali(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildInfoChip(
                                  icon: Icons.star_rounded,
                                  label: rating.toStringAsFixed(1),
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                _buildInfoChip(
                                  icon: Icons.workspace_premium_rounded,
                                  label: ref.tr('rank_${user.rank.toLowerCase()}').toUpperCase(),
                                  color: Colors.amber.shade800,
                                ),
                                if (distance != null && distance > 0) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ${distance.toStringAsFixed(1)} ${ref.watch(languageProvider).languageCode == 'bn' ? 'কিমি' : 'km'}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.red.shade400,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionBtn(
                          icon: Icons.call_rounded,
                          label: ref.tr('call'),
                          color: Colors.green,
                          onTap: () => _makeCall(user.phone),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionBtn(
                          icon: FontAwesomeIcons.whatsapp,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          isFontAwesome: true,
                          onTap: () => _openWhatsApp(user.phone),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionBtn(
                          icon: Icons.chat_bubble_rounded,
                          label: ref.tr('chat'),
                          color: Colors.blue,
                          onTap: () {
                            final currentUid = FirebaseAuth.instance.currentUser?.uid;
                            if (currentUid == null) return;

                            // একটি ইউনিক চ্যাট আইডি তৈরি করা (সবসময় একই ফরম্যাটে যাতে দুইজন ইউজারের একটিই চ্যাট থাকে)
                            final List<String> ids = [currentUid, user.uid];
                            ids.sort(); // আইডিগুলো সর্ট করলে A_B এবং B_A একই আইডি (A_B) দিবে
                            final chatId = 'direct_${ids[0]}_${ids[1]}';

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  requestId: chatId,
                                  otherUserName: user.name,
                                  otherUserId: user.uid,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBloodGroupBadge(String bg, WidgetRef ref) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              bg,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              ref.tr('group'),
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isFontAwesome = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isFontAwesome
                ? FaIcon(icon, color: color, size: 16)
                : Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.notoSansBengali(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
