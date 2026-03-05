import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import 'edit_profile_screen.dart';
import 'reviews_list_screen.dart';
import 'rank_progress_screen.dart';


class PersonalProfileScreen extends ConsumerWidget {
  const PersonalProfileScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: Text('আমার প্রোফাইল', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          userAsync.when(
            data: (user) => user != null ? IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: Colors.red),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(user: user))),
            ) : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('ব্যবহারকারী পাওয়া যায়নি'));
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(context, user),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildRankCard(context, user),
                      const SizedBox(height: 24),
                      if (user.lastDonationDate != null) ...[
                        _buildEligibilityCard(user),
                        const SizedBox(height: 24),
                      ],
                      _buildStatsGrid(user),
                      const SizedBox(height: 24),
                      _buildInfoSection(context, user), // Added context for nav
                      const SizedBox(height: 24),
                      _buildReviewCard(context, user),
                      const SizedBox(height: 24),
                      _buildHelpSection(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'সহযোগিতা ও মতামত',
            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey.shade800),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.facebook_rounded,
            'ফেসবুক পেজ',
            'আমাদের সাথে যুক্ত হন',
            Colors.blue.shade700,
            onTap: () => _launchUrl('https://www.facebook.com/blooddonate'),
          ),
          const Divider(height: 32, thickness: 0.5),
          _buildInfoRow(
            Icons.message_rounded,
            'মতামত ও পরামর্শ',
            'আপনার মতামত জানান',
            Colors.teal,
            onTap: () => _launchUrl('mailto:blooddonate.help@gmail.com?subject=Feedback for Blood Donate App'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
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
                backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                child: user.profileImageUrl == null ? const Icon(Icons.person_rounded, size: 60, color: Colors.red) : null,
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(user.name, style: GoogleFonts.notoSansBengali(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(user.phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEligibilityCard(UserModel user) {
    final nextDate = user.lastDonationDate!.add(const Duration(days: 90));
    final remainingDays = nextDate.difference(DateTime.now()).inDays;
    final isEligible = remainingDays <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEligible ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isEligible ? Colors.green.shade200 : Colors.orange.shade200, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: isEligible ? Colors.green : Colors.orange, shape: BoxShape.circle),
            child: Icon(isEligible ? Icons.check_rounded : Icons.timer_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEligible ? 'আপনি এখন রক্ত দান করতে পারবেন' : 'পরবর্তী রক্তদানের জন্য অপেক্ষা করুন',
                  style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 14, color: isEligible ? Colors.green.shade900 : Colors.orange.shade900),
                ),
                if (!isEligible) Text('আরও $remainingDays দিন বাকি আছে।', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard(BuildContext context, UserModel user) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RankProgressScreen(user: user))),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.orange.shade800]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Colors.white, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('আপনার র‍্যাঙ্ক', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(user.rank.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(UserModel user) {
    return Row(
      children: [
        _buildStatItem('রক্ত দান', '${user.totalDonations} ব্যাগ', Icons.bloodtype, Colors.red),
        const SizedBox(width: 16),
        _buildStatItem('রক্ত গ্রহণ', '${user.totalReceivedBags} ব্যাগ', Icons.volunteer_activism, Colors.green),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
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

  Widget _buildInfoSection(BuildContext context, UserModel user) {
    final location = "${user.address?['thana'] ?? 'অজানা'}, ${user.address?['district'] ?? ''}";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15)],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.bloodtype_outlined, 'রক্তের গ্রুপ', user.bloodGroup ?? 'অজানা', Colors.red),
          const Divider(height: 32, thickness: 0.5),
          _buildInfoRow(Icons.person_outline_rounded, 'লিঙ্গ', user.gender ?? 'অজানা', Colors.blue),
          const Divider(height: 32, thickness: 0.5),
          _buildInfoRow(Icons.location_on_outlined, 'ঠিকানা', location, Colors.green),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (onTap != null) const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, UserModel user) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewsListScreen(userId: user.uid, userName: user.name))),
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
                  Text('ইউজার রিভিউ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(user.averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(' (${user.totalReviews} টি রিভিউ)', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
}
