import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/blood_request_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/blood_request_model.dart';
import '../profile/donor_profile_screen.dart';
import '../requests/create_request_screen.dart';
import '../requests/request_details_screen.dart';
import '../chat/chat_list_screen.dart';
import '../donors/saved_donors_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _celebrationShown = false;
  late String _dailyFact;

  final List<String> _donationFacts = [
    'এক ব্যাগ রক্ত দিয়ে সর্বোচ্চ তিনজনের প্রাণ বাঁচানো সম্ভব। ❤️',
    'রক্তদানের পর শরীরের তরল অংশ ২৪-৪৮ ঘণ্টার মধ্যে পূরণ হয়ে যায়। 💧',
    'নিয়মিত রক্তদান করলে হৃদরোগের ঝুঁকি অনেকাংশে কমে যায়। 🫀',
  ];

  @override
  void initState() {
    super.initState();
    _setDailyFact();
  }

  void _setDailyFact() {
    final now = DateTime.now();
    final dayIndex = DateTime(now.year, now.month, now.day)
        .difference(DateTime(2024, 1, 1))
        .inDays;
    _dailyFact = _donationFacts[dayIndex % _donationFacts.length];
  }

  Future<void> _launchMapUrl(String address) async {
    final Uri url = Uri.parse(
      address.startsWith('http')
          ? address
          : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Map Error: $e");
    }
  }

  void _handleCelebration(UserModel user) {
    if (_celebrationShown) return;
    if (user.rankUpdatePending == true) {
      _celebrationShown = true;
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'rankUpdatePending': false,
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _showCelebrationDialog(user.rank);
      });
    }
  }

  void _showCelebrationDialog(String rank) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.stars_rounded, color: Colors.amber, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('অভিনন্দন!', style: GoogleFonts.notoSansBengali(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('আপনার রক্তদান একটি জীবন বাঁচিয়েছে ❤️', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
              child: Text('র‍্যাঙ্ক: $rank', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ঠিক আছে')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserDataProvider);
    final emergencyRequests = ref.watch(emergencyRequestsProvider);
    final myRequests = ref.watch(myRequestsProvider);
    final myDonations = ref.watch(myDonationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE53935),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('রক্তের আবেদন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
        error: (e, _) => Center(child: Text('ত্রুটি: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('ব্যবহারকারী পাওয়া যায়নি'));
          WidgetsBinding.instance.addPostFrameCallback((_) { _handleCelebration(user); });

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(user),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsSection(user),
                      const SizedBox(height: 24),
                      _buildEligibilityCard(user),
                      const SizedBox(height: 24),
                      _buildActiveActivitySection(myRequests, myDonations),
                      const SizedBox(height: 20),
                      _buildFactCard(),
                      const SizedBox(height: 24),
                      _buildNeedBloodBanner(),
                      const SizedBox(height: 32),
                      _buildSectionHeader('জরুরি রক্তের আবেদনসমূহ'),
                      const SizedBox(height: 16),
                      _buildRequestList(emergencyRequests),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text('সবগুলো দেখুন', style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  SliverAppBar _buildAppBar(UserModel user) {
    final firstName = user.name.split(' ').first;
    final location = "${user.address?['district'] ?? 'অবস্থান'}, ${user.address?['division'] ?? 'নেই'}";

    return SliverAppBar(
      pinned: true,
      expandedHeight: 140,
      toolbarHeight: 70,
      backgroundColor: const Color(0xFFE53935),
      elevation: 0,
      title: Text('হ্যালো, $firstName', style: GoogleFonts.notoSansBengali(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE53935), Color(0xFFB71C1C)]),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14), const SizedBox(width: 4), Text(location, style: const TextStyle(color: Colors.white70, fontSize: 13))]),
                      const SizedBox(height: 8),
                      _buildRankBadge(user.rank),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonorProfileScreen())),
                    child: Hero(
                      tag: 'profile_pic',
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                          child: user.profileImageUrl == null ? const Icon(Icons.person_rounded, color: Colors.red, size: 30) : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()))),
        IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()))),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildRankBadge(String rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.orange.shade800], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(rank.toUpperCase(), style: GoogleFonts.notoSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildStatsSection(UserModel user) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard('দান করেছেন', '${user.totalDonations} ব্যাগ', Icons.bloodtype_rounded, Colors.red),
            const SizedBox(width: 12),
            _buildStatCard('আবেদন করেছেন', '${user.totalRequests} টি', Icons.post_add_rounded, Colors.blue),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard('রক্ত পেয়েছেন', '${user.totalReceivedBags} ব্যাগ', Icons.volunteer_activism_rounded, Colors.green),
            const SizedBox(width: 12),
            _buildStatCard('বাতিল করেছেন', '${user.totalCancelled} টি', Icons.cancel_rounded, Colors.blueGrey),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard('সেভ করা দাতা', '${user.savedDonors.length} জন রক্তদাতা', Icons.favorite_rounded, Colors.orange.shade700, isFullWidth: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedDonorsScreen()))),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool isFullWidth = false, VoidCallback? onTap}) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)), if (onTap != null) Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.3), size: 14)]),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(label, style: GoogleFonts.notoSansBengali(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
    return isFullWidth ? GestureDetector(onTap: onTap, child: SizedBox(width: double.infinity, child: content)) : Expanded(child: GestureDetector(onTap: onTap, child: content));
  }

  Widget _buildEligibilityCard(UserModel user) {
    if (user.lastDonationDate == null) return const SizedBox.shrink();
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
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isEligible ? Colors.green : Colors.orange, shape: BoxShape.circle), child: Icon(isEligible ? Icons.check_rounded : Icons.timer_rounded, color: Colors.white, size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isEligible ? 'আপনি এখন রক্ত দান করতে পারবেন' : 'পরবর্তী রক্তদানের জন্য অপেক্ষা করুন', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 14, color: isEligible ? Colors.green.shade900 : Colors.orange.shade900)), if (!isEligible) Text('আরও $remainingDays দিন বাকি আছে।', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700))])),
        ],
      ),
    );
  }

  Widget _buildFactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: Colors.blue.shade50)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.auto_awesome_rounded, color: Colors.blue.shade600, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('রক্তদানের টিপস', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue.shade900)), const SizedBox(height: 4), Text(_dailyFact, style: GoogleFonts.notoSansBengali(fontSize: 13, color: Colors.blueGrey.shade700, height: 1.4))])),
        ],
      ),
    );
  }

  Widget _buildActiveActivitySection(AsyncValue<List<BloodRequestModel>> myReq, AsyncValue<List<BloodRequestModel>> myDon) {
    return Column(
      children: [
        myReq.when(
          data: (requests) {
            final active = requests.where((r) => r.status == 'pending' || r.status == 'accepted' || r.status == 'donated' || r.status == 'cancelled').toList();
            if (active.isEmpty) return const SizedBox.shrink();
            return Column(children: active.map<Widget>((req) {
              String title = 'আপনার রক্ত প্রয়োজন'; Color color = Colors.blue;
              if (req.status == 'cancelled') { title = 'আপনার বাতিলকৃত আবেদন'; color = Colors.grey; }
              else if (req.status == 'pending') { title = 'আবেদন পেন্ডিং আছে'; color = Colors.orange; }
              return _buildActivityCard(req, title, color);
            }).toList());
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
        myDon.when(
          data: (donations) {
            final active = donations.where((r) => r.status == 'accepted' || r.status == 'donated' || r.status == 'cancelled').toList();
            if (active.isEmpty) return const SizedBox.shrink();
            return Column(children: active.map<Widget>((req) {
              String title = 'আপনি রক্ত দিচ্ছেন'; Color color = Colors.green;
              if (req.status == 'cancelled') { title = 'রক্তদান বাতিল হয়েছে'; color = Colors.grey; }
              return _buildActivityCard(req, title, color);
            }).toList());
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildActivityCard(BloodRequestModel req, String title, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.15))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.history_edu_rounded, color: color, size: 20)),
        title: Text(title, style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        subtitle: Text(req.hospitalName, style: const TextStyle(fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req))),
      ),
    );
  }

  Widget _buildRequestList(AsyncValue<List<BloodRequestModel>> requestsAsync) {
    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (requests) {
        if (requests.isEmpty) return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Text('কোন পেন্ডিং আবেদন নেই', style: TextStyle(color: Colors.grey.shade500))));
        final sorted = List<BloodRequestModel>.from(requests)..sort((a, b) => (a.isEmergency && !b.isEmergency) ? -1 : 1);
        return ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sorted.length,
          itemBuilder: (context, index) => _buildRequestCard(sorted[index]),
        );
      },
    );
  }

  Widget _buildRequestCard(BloodRequestModel req) {
    final bool isUrgent = req.isEmergency;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))], border: isUrgent ? Border.all(color: Colors.red.shade100, width: 1.5) : null),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(gradient: isUrgent ? LinearGradient(colors: [Colors.red, Colors.red.shade800]) : LinearGradient(colors: [Colors.red.shade50, Colors.red.shade100]), borderRadius: BorderRadius.circular(18)),
                child: Center(child: Text(req.bloodGroup, style: TextStyle(color: isUrgent ? Colors.white : Colors.red, fontWeight: FontWeight.bold, fontSize: 22))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Flexible(child: Text(req.patientName.isEmpty ? 'নামহীন রোগী' : req.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), if (isUrgent) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)), child: const Text('জরুরি', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))]]),
                    const SizedBox(height: 6),
                    Text(req.hospitalName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500), const SizedBox(width: 4), Text('${req.district}, ${req.thana}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))]),
                  ],
                ),
              ),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.map_rounded, color: Colors.blue, size: 22), onPressed: () => _launchMapUrl(req.mapUrl ?? req.hospitalName), padding: EdgeInsets.zero, constraints: const BoxConstraints())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeedBloodBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('আপনার কি রক্ত প্রয়োজন?', style: GoogleFonts.notoSansBengali(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('সরাসরি রক্তদাতার সাথে যোগাযোগ করতে এখনই আবেদন করুন।', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
            child: const Text('আবেদন করুন', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
