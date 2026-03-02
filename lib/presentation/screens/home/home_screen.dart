import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blood_request_provider.dart';
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
  
  Future<void> _launchMapUrl(String address) async {
    final Uri url = Uri.parse(address.startsWith('http') 
        ? address 
        : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Map Error: $e");
    }
  }

  void _showCelebrationDialog(String rank) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, color: Colors.amber, size: 80),
            const SizedBox(height: 16),
            Text('অভিনন্দন!', style: GoogleFonts.notoSansBengali(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 8),
            Text(
              'আপনি সফলভাবে রক্তদান সম্পন্ন করেছেন। আপনার এই মহৎ কাজ একটি জীবন বাঁচিয়েছে!',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansBengali(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(12)),
              child: Text('আপনার বর্তমান র‍্যাঙ্ক: $rank', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ধন্যবাদ'),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(currentUserDataProvider);
    final emergencyRequests = ref.watch(emergencyRequestsProvider);
    final myRequestsAsync = ref.watch(myRequestsProvider);
    final myDonationsAsync = ref.watch(myDonationsProvider);

    userDataAsync.whenData((user) {
      if (user != null && (user.toMap()['rankUpdatePending'] ?? false)) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({'rankUpdatePending': false});
        Future.delayed(const Duration(milliseconds: 500), () => _showCelebrationDialog(user.rank));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, userDataAsync),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsSection(userDataAsync),
                  const SizedBox(height: 20),
                  _buildEligibilityCard(userDataAsync),
                  const SizedBox(height: 20),
                  
                  // সচল কার্যক্রম (বাতিল সহ সব স্ট্যাটাস সাপোর্ট)
                  _buildActiveActivitySection(myRequestsAsync, myDonationsAsync, context),
                  
                  const SizedBox(height: 10),
                  _buildNeedBloodBanner(context),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'রক্তের আবেদনসমূহ',
                        style: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(onPressed: () {}, child: const Text('সবগুলো', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildRequestList(emergencyRequests, context),
                  const SizedBox(height: 100), 
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('রক্তের আবেদন'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AsyncValue userDataAsync) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: const Color(0xFFE53935),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE53935), Color(0xFFB71C1C)]),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 55, left: 24, right: 24),
            child: userDataAsync.when(
              data: (user) {
                String firstName = user?.name.split(' ').first ?? 'ব্যবহারকারী';
                String location = user?.address != null ? "${user?.address?['district'] ?? ''}, ${user?.address?['division'] ?? ''}" : "অবস্থান সেট করা নেই";
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('হ্যালো, $firstName', style: GoogleFonts.notoSansBengali(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        if (user != null && user.rank != 'Newbie')
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                            child: Text(user.rank, style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(location, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()))),
        IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()))),
        IconButton(icon: const Icon(Icons.person_outline_rounded, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonorProfileScreen()))),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsSection(AsyncValue userDataAsync) {
    return userDataAsync.when(
      data: (user) {
        return Column(
          children: [
            Row(
              children: [
                _buildStatCard('দান করেছেন', '${user?.totalDonations ?? 0} ব্যাগ', Icons.bloodtype, Colors.red, () {}),
                const SizedBox(width: 12),
                _buildStatCard('আবেদন করেছেন', '${user?.totalRequests ?? 0} টি', Icons.post_add_rounded, Colors.blue, () {}),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard('রক্ত পেয়েছেন', '${user?.totalReceivedBags ?? 0} ব্যাগ', Icons.volunteer_activism_rounded, Colors.green, () {}),
                const SizedBox(width: 12),
                _buildStatCard('বাতিল করেছেন', '${user?.totalCancelled ?? 0} টি', Icons.cancel_outlined, Colors.grey, () {}),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard('সেভ করেছেন', '${user?.savedDonors.length ?? 0} জন রক্তদাতা', Icons.favorite, Colors.orange, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedDonorsScreen()));
            }),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
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
      ),
    );
  }

  Widget _buildRequestList(AsyncValue requestsAsync, BuildContext context) {
    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) return const Center(child: Text('কোন পেন্ডিং আবেদন নেই'));
        final sortedRequests = List.from(requests)..sort((a, b) => (a.isEmergency && !b.isEmergency) ? -1 : 1);
        return ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedRequests.length,
          itemBuilder: (context, index) {
            final req = sortedRequests[index];
            bool isUrgent = req.isEmergency;
            double progress = req.bloodBags > 0 ? (req.donatedBags / req.bloodBags) : 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: isUrgent ? Border.all(color: Colors.red.shade200, width: 1.5) : null, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(20), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req))), child: ClipRRect(borderRadius: BorderRadius.circular(20), child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Container(width: 70, color: isUrgent ? Colors.red : const Color(0xFFE53935).withOpacity(0.05), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(req.bloodGroup, style: TextStyle(color: isUrgent ? Colors.white : const Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 22)), Text('গ্রুপ', style: TextStyle(color: isUrgent ? Colors.white70 : const Color(0xFFE53935), fontSize: 10))])), Expanded(child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(req.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), if (isUrgent) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)), child: const Text('জরুরি', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))]), const SizedBox(height: 4), Text(req.hospitalName, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Row(children: [const Icon(Icons.location_on_rounded, size: 14, color: Colors.blueGrey), const SizedBox(width: 4), Text('${req.district}, ${req.thana}', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 11))]), const SizedBox(height: 10), Text('সংগ্রহ: ${req.donatedBags}/${req.bloodBags} ব্যাগ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red))]))), Column(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(icon: const Icon(Icons.map_outlined, color: Colors.blue), onPressed: () => _launchMapUrl(req.mapUrl ?? req.hospitalName)), const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey), const SizedBox(width: 12)])]))))),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEligibilityCard(AsyncValue userDataAsync) {
    return userDataAsync.when(data: (user) { if (user == null || user.lastDonationDate == null) return const SizedBox.shrink(); final nextDonationDate = user.lastDonationDate!.add(const Duration(days: 90)); final remainingDays = nextDonationDate.difference(DateTime.now()).inDays; final isEligible = remainingDays <= 0; return Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isEligible ? Colors.green.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: isEligible ? Colors.green.shade200 : Colors.orange.shade200)), child: Row(children: [Icon(isEligible ? Icons.check_circle : Icons.timer, color: isEligible ? Colors.green : Colors.orange, size: 30), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isEligible ? 'আপনি এখন রক্ত দান করতে পারবেন' : 'পরবর্তী রক্তদানের জন্য অপেক্ষা করুন', style: const TextStyle(fontWeight: FontWeight.bold)), if (!isEligible) Text('আরও $remainingDays দিন বাকি আছে।', style: const TextStyle(fontSize: 12, color: Colors.blueGrey))]))])); }, loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink());
  }

  Widget _buildActiveActivitySection(AsyncValue myReq, AsyncValue myDon, BuildContext context) {
    return Column(children: [myReq.when(data: (requests) { 
      // এখন এখানে 'accepted', 'donated' এবং 'cancelled' স্ট্যাটাসগুলোও দেখা যাবে সাময়িকভাবে
      final activeOnes = requests.where((r) => r.status == 'accepted' || r.status == 'donated' || r.status == 'cancelled').toList(); 
      return Column(children: activeOnes.map<Widget>((req) => _buildActivityCard(req, req.status == 'cancelled' ? 'বাতিল করা আবেদন' : 'আপনার রক্ত প্রয়োজন', req.status == 'cancelled' ? Colors.grey : Colors.blue, context)).toList()); 
    }, loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink()), myDon.when(data: (donations) { final activeDons = donations.where((r) => r.status == 'accepted' || r.status == 'donated').toList(); return Column(children: activeDons.map<Widget>((req) => _buildActivityCard(req, 'আপনি রক্ত দিচ্ছেন', Colors.green, context)).toList()); }, loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink())]);
  }

  Widget _buildActivityCard(req, String title, Color themeColor, BuildContext context) {
    return Card(color: themeColor.withOpacity(0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: themeColor.withOpacity(0.3))), child: ListTile(title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: themeColor)), subtitle: Text('হাসপাতাল: ${req.hospitalName}\nব্যাগ: ${req.donatedBags}/${req.bloodBags}'), trailing: const Icon(Icons.arrow_forward_ios, size: 14), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req)))));
  }

  Widget _buildNeedBloodBanner(BuildContext context) { return Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF263238), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('আপনার কি রক্ত প্রয়োজন?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 4), const Text('নিমিষেই রক্তদাতা খুঁজে পেতে এখনই আবেদন করুন।', style: TextStyle(color: Colors.white70, fontSize: 12)), const SizedBox(height: 12), ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen())), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF263238), minimumSize: const Size(100, 36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('আবেদন করুন', style: TextStyle(fontSize: 13)))])); }
}
