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
import 'notification_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _celebrationShown = false;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Icon(Icons.stars_rounded, color: Colors.amber, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'অভিনন্দন!',
              style: GoogleFonts.notoSansBengali(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'আপনার রক্তদান একটি জীবন বাঁচিয়েছে ❤️',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'র‍্যাঙ্ক: $rank',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
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
    final userAsync = ref.watch(currentUserDataProvider);
    final emergencyRequests = ref.watch(emergencyRequestsProvider);
    final myRequests = ref.watch(myRequestsProvider);
    final myDonations = ref.watch(myDonationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE53935),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'রক্তের আবেদন',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
        ),
      ),
      body: userAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.red)),
        error: (e, _) => Center(child: Text('ত্রুটি: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('ব্যবহারকারী পাওয়া যায়নি'));
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleCelebration(user);
          });

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(user),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsSection(user),
                      const SizedBox(height: 20),
                      _buildEligibilityCard(user),
                      const SizedBox(height: 20),
                      _buildActiveActivitySection(myRequests, myDonations),
                      const SizedBox(height: 20),
                      _buildNeedBloodBanner(),
                      const SizedBox(height: 28),
                      Text(
                        'জরুরি রক্তের আবেদনসমূহ',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
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

  // ================= APP BAR =================

  SliverAppBar _buildAppBar(UserModel user) {
    final firstName = user.name.split(' ').first;
    final location =
        "${user.address?['district'] ?? 'অবস্থান'}, ${user.address?['division'] ?? 'নেই'}";

    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      toolbarHeight: 70,
      backgroundColor: const Color(0xFFE53935),
      elevation: 0,
      title: Row(
        children: [
          Text(
            'হ্যালো, $firstName',
            style: GoogleFonts.notoSansBengali(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 8),
          _buildRankBadge(user.rank),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonorProfileScreen())),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildRankBadge(String rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            rank.toUpperCase(),
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ================= STATS SECTION =================

  Widget _buildStatsSection(UserModel user) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard('দান করেছেন', '${user.totalDonations} ব্যাগ', Icons.bloodtype, Colors.red),
            const SizedBox(width: 12),
            _buildStatCard('আবেদন করেছেন', '${user.totalRequests} টি', Icons.post_add_rounded, Colors.blue),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard('রক্ত পেয়েছেন', '${user.totalReceivedBags} ব্যাগ', Icons.volunteer_activism_rounded, Colors.green),
            const SizedBox(width: 12),
            _buildStatCard('বাতিল করেছেন', '${user.totalCancelled} টি', Icons.cancel_outlined, Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ================= ELIGIBILITY CARD =================

  Widget _buildEligibilityCard(UserModel user) {
    if (user.lastDonationDate == null) return const SizedBox.shrink();
    final nextDate = user.lastDonationDate!.add(const Duration(days: 90));
    final remainingDays = nextDate.difference(DateTime.now()).inDays;
    final isEligible = remainingDays <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEligible ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isEligible ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(isEligible ? Icons.check_circle : Icons.timer, color: isEligible ? Colors.green : Colors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEligible ? 'আপনি এখন রক্ত দান করতে পারবেন' : 'পরবর্তী রক্তদানের জন্য অপেক্ষা করুন',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                if (!isEligible) Text('আরও $remainingDays দিন বাকি আছে।', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= ACTIVE ACTIVITY =================

  Widget _buildActiveActivitySection(AsyncValue<List<BloodRequestModel>> myReq, AsyncValue<List<BloodRequestModel>> myDon) {
    return Column(
      children: [
        myReq.when(
          data: (requests) {
            // Updated: Included 'pending' so users can see and cancel their own requests
            final active = requests.where((r) => 
              r.status == 'pending' || 
              r.status == 'accepted' || 
              r.status == 'donated' || 
              r.status == 'cancelled'
            ).toList();
            
            if (active.isEmpty) return const SizedBox.shrink();
            
            return Column(
              children: active.map<Widget>((req) {
                String title = 'আপনার রক্ত প্রয়োজন';
                Color color = Colors.blue;
                
                if (req.status == 'cancelled') {
                  title = 'আপনার বাতিলকৃত আবেদন';
                  color = Colors.grey;
                } else if (req.status == 'pending') {
                  title = 'আবেদন পেন্ডিং আছে';
                  color = Colors.orange;
                }
                
                return _buildActivityCard(req, title, color);
              }).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
        myDon.when(
          data: (donations) {
            final active = donations.where((r) => 
              r.status == 'accepted' || 
              r.status == 'donated' || 
              r.status == 'cancelled'
            ).toList();
            
            if (active.isEmpty) return const SizedBox.shrink();
            
            return Column(
              children: active.map<Widget>((req) {
                String title = 'আপনি রক্ত দিচ্ছেন';
                Color color = Colors.green;
                
                if (req.status == 'cancelled') {
                  title = 'রক্তদান বাতিল হয়েছে';
                  color = Colors.grey;
                }
                
                return _buildActivityCard(req, title, color);
              }).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildActivityCard(BloodRequestModel req, String title, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.06),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.15))),
      child: ListTile(
        dense: true,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        subtitle: Text('হাসপাতাল: ${req.hospitalName}', style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req))),
      ),
    );
  }

  // ================= REQUEST LIST =================

  Widget _buildRequestList(AsyncValue<List<BloodRequestModel>> requestsAsync) {
    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (requests) {
        if (requests.isEmpty) return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text('কোন পেন্ডিং আবেদন নেই', style: TextStyle(color: Colors.grey.shade500))));
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUrgent ? Border.all(color: Colors.red.shade200, width: 1.2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: isUrgent ? Colors.red : Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(req.bloodGroup, style: TextStyle(color: isUrgent ? Colors.white : Colors.red, fontWeight: FontWeight.bold, fontSize: 16))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.patientName.isEmpty ? 'নামহীন রোগী' : req.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(req.hospitalName, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    Text('${req.district}, ${req.thana}', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                  ],
                ),
              ),
              if (isUrgent) Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                child: const Text('জরুরি', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 4),
              IconButton(icon: const Icon(Icons.map_outlined, color: Colors.blue, size: 20), onPressed: () => _launchMapUrl(req.mapUrl ?? req.hospitalName)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeedBloodBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF263238), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('আপনার কি রক্ত প্রয়োজন?', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('নিমিষেই রক্তদাতা খুঁজে পেতে আবেদন করুন।', style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 16)),
              child: const Text('আবেদন করুন', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
