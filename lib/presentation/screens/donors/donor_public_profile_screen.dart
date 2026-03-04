import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/user_model.dart';
import '../chat/chat_screen.dart';
import '../profile/reviews_list_screen.dart';

class DonorPublicProfileScreen extends StatelessWidget {
  final UserModel donor;

  const DonorPublicProfileScreen({super.key, required this.donor});

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (e) { debugPrint("Call Error: $e"); }
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: const Text('রক্তদাতার প্রোফাইল'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildInfoSection(),
                  const SizedBox(height: 24),
                  _buildReviewCard(context), // Added Review Card
                  const SizedBox(height: 32),
                  _buildActionButtons(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.red.shade50,
            backgroundImage: donor.profileImageUrl != null ? NetworkImage(donor.profileImageUrl!) : null,
            child: donor.profileImageUrl == null ? const Icon(Icons.person_rounded, size: 60, color: Colors.red) : null,
          ),
          const SizedBox(height: 16),
          Text(donor.name, style: GoogleFonts.notoSansBengali(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildRankBadge(donor.rank),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 4),
              Text(donor.averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(' (${donor.totalReviews} টি রিভিউ)', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatItem('রক্ত দিয়েছেন', '${donor.totalDonations} বার', Icons.bloodtype, Colors.red),
        const SizedBox(width: 16),
        _buildStatItem('র‍্যাঙ্ক', donor.rank, Icons.workspace_premium, Colors.amber.shade700),
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

  Widget _buildInfoSection() {
    final location = "${donor.address?['thana'] ?? 'অজানা'}, ${donor.address?['district'] ?? ''}";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.bloodtype_outlined, 'রক্তের গ্রুপ', donor.bloodGroup ?? 'অজানা', Colors.red),
          const Divider(height: 32),
          _buildInfoRow(Icons.location_on_outlined, 'বর্তমান ঠিকানা', location, Colors.blue),
          const Divider(height: 32),
          _buildInfoRow(Icons.calendar_month_outlined, 'সর্বশেষ রক্তদান', donor.lastDonationDate != null ? DateFormat('dd MMM yyyy').format(donor.lastDonationDate!) : 'এখনো রক্ত দেননি', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context) {
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
                  const Text('ইউজার রিভিউ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(donor.averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(' (${donor.totalReviews} টি রিভিউ)', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _makeCall(donor.phone),
                icon: const Icon(Icons.call_rounded),
                label: const Text('কল করুন'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(0, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(requestId: 'direct_${donor.uid}', otherUserName: donor.name))),
                icon: const Icon(Icons.chat_bubble_rounded),
                label: const Text('মেসেজ দিন'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size(0, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _openWhatsApp(donor.whatsappNumber ?? donor.phone),
          icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
          label: const Text('হোয়াটসঅ্যাপে মেসেজ দিন'),
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
