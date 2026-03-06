import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../chat/chat_screen.dart';
import '../profile/reviews_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/language_provider.dart';

class DonorPublicProfileScreen extends ConsumerWidget {
  final UserModel donor;

  const DonorPublicProfileScreen({super.key, required this.donor});

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Call Error: $e");
    }
  }

  Future<void> _toggleSaveDonor(
    WidgetRef ref,
    String donorId,
    String currentUserId,
    List<String> currentlySaved,
  ) async {
    List<String> newList = List.from(currentlySaved);
    if (newList.contains(donorId)) {
      newList.remove(donorId);
    } else {
      newList.add(donorId);
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .update({'savedDonors': newList});
    ref.invalidate(currentUserDataProvider);
  }

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    // Clean phone number
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserDataProvider).value;
    final isMe = currentUser?.uid == donor.uid;
    final savedDonors = currentUser?.savedDonors ?? [];
    final isSaved = savedDonors.contains(donor.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: Text(ref.tr('donor_profile')),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (!isMe)
            IconButton(
              icon: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: Colors.orange,
              ),
              onPressed: () => _toggleSaveDonor(
                ref,
                donor.uid,
                currentUser!.uid,
                savedDonors,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(ref),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildStatsRow(ref),
                  const SizedBox(height: 24),
                  _buildInfoSection(ref),
                  const SizedBox(height: 24),
                  _buildReviewCard(context, ref), // Added Review Card
                  const SizedBox(height: 32),
                  _buildActionButtons(context, ref, isMe: isMe),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    final bool canDonate = donor.isAvailable && (donor.lastDonationDate == null || DateTime.now().difference(donor.lastDonationDate!).inDays >= 90);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.red.shade50,
                backgroundImage: donor.profileImageUrl != null ? NetworkImage(donor.profileImageUrl!) : null,
                child: donor.profileImageUrl == null ? const Icon(Icons.person_rounded, size: 60, color: Colors.red) : null,
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: canDonate ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(donor.name, style: GoogleFonts.notoSansBengali(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (!canDonate)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(
                donor.isAvailable ? ref.tr('not_available_to_donate') : ref.tr('not_willing_to_donate'),
                style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          _buildRankBadge(ref.tr('rank_${donor.rank.toLowerCase()}')),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 4),
              Text(donor.averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(' (${donor.totalReviews} ${ref.tr('reviews_count')})', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(String rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.orange.shade800]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(rank.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }

  Widget _buildStatsRow(WidgetRef ref) {
    return Row(
      children: [
        _buildStatItem(ref.tr('donation_count'), '${donor.totalDonations} ${ref.tr('times')}', Icons.bloodtype, Colors.red),
        const SizedBox(width: 16),
        _buildStatItem(ref.tr('rank'), ref.tr('rank_${donor.rank.toLowerCase()}'), Icons.workspace_premium, Colors.amber.shade700),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(WidgetRef ref) {
    final location = "${donor.address?['thana'] ?? ref.tr('unknown')}, ${donor.address?['district'] ?? ''}";
    final lastDonation = donor.lastDonationDate;
    final daysSinceLastDonation = lastDonation != null ? DateTime.now().difference(lastDonation).inDays : 999;
    final daysRemaining = 90 - daysSinceLastDonation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.bloodtype_outlined, ref.tr('blood_group'), donor.bloodGroup ?? ref.tr('unknown'), Colors.red),
          const Divider(height: 32),
          _buildInfoRow(Icons.location_on_outlined, ref.tr('location'), location, Colors.blue),
          const Divider(height: 32),
          _buildInfoRow(
            Icons.calendar_month_outlined,
            ref.tr('last_donation'),
            lastDonation != null ? DateFormat('dd MMM yyyy', ref.watch(languageProvider).languageCode).format(lastDonation) : ref.tr('never_donated'),
            Colors.orange,
            trailing: lastDonation != null && daysRemaining > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text('$daysRemaining ${ref.tr('days_left')}', style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                : null,
          ),
          if (donor.isAvailable == false) ...[
            const Divider(height: 32),
            _buildInfoRow(Icons.do_not_disturb_on_outlined, ref.tr('status'), ref.tr('not_willing_to_donate'), Colors.red.shade400),
          ]
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color, {Widget? trailing}) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewsListScreen(userId: donor.uid, userName: donor.name))),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
        child: Row(
          children: [
            const Icon(Icons.rate_review_outlined, color: Colors.blue, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ref.tr('user_reviews'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(donor.averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(' (${donor.totalReviews} ${ref.tr('reviews_count')})', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, {bool isMe = false}) {
    if (isMe) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _makeCall(donor.phone),
                icon: const Icon(Icons.call_rounded),
                label: Text(ref.tr('call_now')),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(0, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null) {
                    List<String> ids = [currentUser.uid, donor.uid];
                    ids.sort();
                    final chatId = 'direct_${ids[0]}_${ids[1]}';
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          requestId: chatId,
                          otherUserName: donor.name,
                          otherUserId: donor.uid,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.chat_bubble_rounded),
                label: Text(ref.tr('send_message')),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size(0, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _openWhatsApp(donor.whatsappNumber ?? donor.phone),
          icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
          label: Text(ref.tr('whatsapp_message')),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}
