import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/blood_request_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/blood_request_model.dart';
import '../profile/personal_profile_screen.dart';
import '../requests/create_request_screen.dart';
import '../requests/request_details_screen.dart';
import '../requests/request_list_screen.dart';
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
    final dayIndex = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(2024, 1, 1)).inDays;
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
            Text(
              'অভিনন্দন!',
              style: GoogleFonts.notoSansBengali(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'আপনার রক্তদান একটি জীবন বাঁচিয়েছে ❤️',
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
                'র‍্যাঙ্ক: $rank',
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
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
        ),
        backgroundColor: const Color(0xFFE53935),
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: Text(
          'রক্তের আবেদন',
          style: GoogleFonts.notoSansBengali(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        elevation: 4,
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

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentUserDataProvider);
              ref.invalidate(emergencyRequestsProvider);
              ref.invalidate(myRequestsProvider);
              ref.invalidate(myDonationsProvider);
              await Future.delayed(const Duration(seconds: 1));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                _buildAppBar(user),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeSection(user),
                        const SizedBox(height: 24),
                        _buildQuickStats(user),
                        const SizedBox(height: 24),
                        _buildActiveActivitySection(
                          myRequests,
                          myDonations,
                        ),
                        _buildNextDonationSection(user),
                        _buildFactCard(),
                        const SizedBox(height: 32),
                        _buildSectionHeader('জরুরি রক্তের আবেদনসমূহ', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RequestListScreen(),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        _buildRequestList(emergencyRequests, user.uid),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'আপনার ড্যাশবোর্ড',
          style: GoogleFonts.notoSansBengali(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'আজকের রক্তদান একটি জীবন বাঁচাতে পারে',
          style: GoogleFonts.notoSansBengali(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(UserModel user) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatBox('মোট দান', '${user.totalDonations}', Colors.red, Icons.bloodtype),
            const SizedBox(width: 12),
            _buildStatBox('আবেদন', '${user.totalRequests}', Colors.blue, Icons.campaign),
            const SizedBox(width: 12),
            _buildStatBox(
              'সেভ করা',
              '${user.savedDonors.length}',
              Colors.orange,
              Icons.favorite,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedDonorsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatBox('ব্যাগ পেয়েছেন', '${user.totalReceivedBags}', Colors.green, Icons.opacity),
            const SizedBox(width: 12),
            _buildStatBox('বাতিল আবেদন', '${user.totalCancelled}', Colors.blueGrey, Icons.cancel_outlined),
            const SizedBox(width: 12),
            _buildStatBox(
              'গড় রেটিং',
              user.averageRating.toStringAsFixed(1),
              Colors.amber,
              Icons.star_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(String title, String value, Color color, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveActivitySection(
    AsyncValue<List<BloodRequestModel>> myReq,
    AsyncValue<List<BloodRequestModel>> myDon,
  ) {
    return myReq.when(
      data: (requests) {
        final reqActive = requests
            .where((r) => r.status == 'accepted' || r.status == 'donated')
            .toList();

        return myDon.when(
          data: (donations) {
            final donActive = donations
                .where(
                  (r) =>
                      r.status == 'accepted' ||
                      r.status == 'donated' ||
                      r.status == 'completed',
                )
                .toList();
            final others = donActive
                .where((d) => d.status != 'completed')
                .toList();

            if (reqActive.isEmpty && others.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                ...reqActive.map<Widget>(
                  (req) => _buildActivityCard(
                    req,
                    'আপনার রক্ত প্রয়োজন',
                    Colors.blue,
                  ),
                ),
                if (reqActive.isNotEmpty && others.isNotEmpty)
                  const SizedBox(height: 8),
                ...others.map<Widget>(
                  (req) => _buildActivityCard(
                    req,
                    'আপনি রক্ত দিচ্ছেন',
                    Colors.green,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildActivityCard(BloodRequestModel req, String title, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            title.contains('নিচ্ছেন') ? Icons.volunteer_activism : Icons.history_edu,
            color: color,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.notoSansBengali(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              req.hospitalName,
              style: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'অবস্থা: ${req.status.toUpperCase()}',
              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color.withValues(alpha: 0.5)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req)),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSansBengali(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'সবগুলো দেখুন',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar(UserModel user) {
    final firstName = user.name.split(' ').first;
    final location =
        "${user.address?['district'] ?? 'অবস্থান'}, ${user.address?['division'] ?? 'নেই'}";
    return SliverAppBar(
      pinned: true,
      expandedHeight: 140,
      toolbarHeight: 70,
      backgroundColor: const Color(0xFFE53935),
      elevation: 0,
      title: Text(
        'হ্যালো, $firstName',
        style: GoogleFonts.notoSansBengali(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
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
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildRankBadge(user.rank),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PersonalProfileScreen(),
                      ),
                    ),
                    child: Hero(
                      tag: 'profile_pic',
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          backgroundImage: user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!)
                              : null,
                          child: user.profileImageUrl == null
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: Colors.red,
                                  size: 30,
                                )
                              : null,
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
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatListScreen()),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildRankBadge(String rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            rank.toUpperCase(),
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.blue.shade50),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.blue.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'রক্তদানের টিপস',
                  style: GoogleFonts.notoSansBengali(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dailyFact,
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 13,
                    color: Colors.blueGrey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextDonationSection(UserModel user) {
    if (user.lastDonationDate == null) return const SizedBox.shrink();

    final nextDate = user.lastDonationDate!.add(const Duration(days: 90));
    final daysLeft = nextDate.difference(DateTime.now()).inDays;
    final bool canDonate = daysLeft <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: canDonate
              ? [Colors.green.shade50, Colors.white]
              : [Colors.orange.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: canDonate ? Colors.green.shade100 : Colors.orange.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: canDonate ? Colors.green.shade100 : Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              canDonate ? Icons.check_circle_rounded : Icons.timer_rounded,
              color: canDonate ? Colors.green : Colors.orange,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canDonate ? 'আপনি এখন রক্তদান করতে পারবেন' : 'পরবর্তী রক্তদানের সময়',
                  style: GoogleFonts.notoSansBengali(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: canDonate ? Colors.green.shade900 : Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  canDonate
                      ? 'আপনার শেষ রক্তদানের পর ৩ মাস অতিবাহিত হয়েছে।'
                      : 'আর মাত্র $daysLeft দিন পর আপনি আবার রক্তদান করতে পারবেন।',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 13,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(AsyncValue<List<BloodRequestModel>> requestsAsync, String? currentUserId) {
    return requestsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.red)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (requests) {
        final filteredRequests = requests.where((r) => r.requesterId != currentUserId).toList();
        
        if (filteredRequests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'কোন পেন্ডিং আবেদন নেই',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          );
        }
        final sorted = List<BloodRequestModel>.from(filteredRequests)
          ..sort((a, b) => (a.isEmergency && !b.isEmergency) ? -1 : 1);
        final top3 = sorted.take(3).toList();
        return Column(
          children: top3.map((req) => _buildRequestCard(req)).toList(),
        );
      },
    );
  }

  Widget _buildRequestCard(BloodRequestModel req) {
    final bool isUrgent = req.isEmergency;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isUrgent ? Colors.red : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        req.bloodGroup,
                        style: TextStyle(
                          color: isUrgent ? Colors.white : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                req.patientName.isEmpty
                                    ? 'নামহীন রোগী'
                                    : req.patientName,
                                style: GoogleFonts.notoSansBengali(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (isUrgent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'জরুরি',
                                  style: GoogleFonts.notoSansBengali(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          req.hospitalName,
                          style: GoogleFonts.notoSansBengali(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_right_rounded,
                      color: Colors.blue.shade400,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text(
                        '${req.district}, ${req.thana}',
                        style: GoogleFonts.notoSansBengali(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _launchMapUrl(req.mapUrl ?? req.hospitalName),
                    child: Text(
                      'ম্যাপ দেখুন',
                      style: GoogleFonts.notoSansBengali(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
