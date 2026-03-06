import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
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
import '../history/history_screen.dart';
import '../profile/reviews_list_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _celebrationShown = false;
  String _dailyFact = 'রক্তদান করুন, জীবন বাঁচান। ❤️';
  List<String> _donationFacts = [];

  @override
  void initState() {
    super.initState();
    _loadDonationFacts();
  }

  Future<void> _loadDonationFacts() async {
    try {
      final String response = await rootBundle.loadString('assets/donation_facts.json');
      final List<dynamic> data = json.decode(response);
      if (mounted) {
        setState(() {
          _donationFacts = data.cast<String>();
          _setDailyFact();
        });
      }
    } catch (e) {
      debugPrint("Error loading donation facts: $e");
    }
  }

  void _setDailyFact() {
    if (_donationFacts.isEmpty) return;
    final now = DateTime.now();
    final index = now.day % _donationFacts.length;
    setState(() {
      _dailyFact = _donationFacts[index];
    });
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

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("URL Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserDataProvider);
    final emergencyRequests = ref.watch(emergencyRequestsProvider);
    final myRequests = ref.watch(myRequestsProvider);
    final myDonations = ref.watch(myDonationsProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: _buildDrawer(context, userAsync.value),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
        backgroundColor: const Color(0xFFE53935),
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: Text('রক্তের আবেদন', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 4,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
        error: (e, _) => Center(child: Text('ত্রুটি: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('ব্যবহারকারী পাওয়া যায়নি'));
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _handleCelebration(user);
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
                        _buildActiveActivitySection(myRequests, myDonations),
                        _buildNextDonationSection(user),
                        _buildFactCard(),
                        const SizedBox(height: 32),
                        _buildSectionHeader('জরুরি রক্তের আবেদনসমূহ', () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestListScreen()));
                        }),
                        const SizedBox(height: 16),
                        _buildRequestList(emergencyRequests, user),
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

  // --- UI Builder Methods ---

  Widget _buildDrawer(BuildContext context, UserModel? user) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          _buildDrawerHeader(user),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildDrawerSectionTitle('সাধারণ'),
                  _buildDrawerItem(
                    icon: Icons.settings_suggest_rounded,
                    title: 'সেটিংস ও প্রোফাইল',
                    color: Colors.blue.shade700,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalProfileScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.favorite_rounded,
                    title: 'সেভ করা ডোনার',
                    color: Colors.red.shade600,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedDonorsScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.history_rounded,
                    title: 'অ্যাক্টিভিটি হিস্ট্রি',
                    color: Colors.orange.shade700,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(thickness: 0.5),
                  ),
                  _buildDrawerSectionTitle('অন্যান্য'),
                  _buildDrawerItem(
                    icon: Icons.local_hospital_rounded,
                    title: 'হাসপাতাল ও ক্লিনিক',
                    subtitle: 'শীঘ্রই আসছে',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('এই ফিচারটি শীঘ্রই আসছে!')));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.headset_mic_rounded,
                    title: 'সাপোর্ট ও ফিডব্যাক',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(context);
                      _showSupportDialog();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: 'আমাদের সম্পর্কে',
                    color: Colors.grey.shade700,
                    onTap: () { Navigator.pop(context); },
                  ),
                ],
              ),
            ),
          ),
          _buildDrawerFooter(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(UserModel? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        color: Color(0xFFB71C1C),
        image: DecorationImage(
          image: NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'), // Subtle pattern overlay
          opacity: 0.1,
          repeat: ImageRepeat.repeat,
        ),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: user?.profileImageUrl != null ? NetworkImage(user!.profileImageUrl!) : null,
              child: user?.profileImageUrl == null ? const Icon(Icons.person, size: 45, color: Color(0xFFE53935)) : null,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            user?.name ?? 'অতিথি',
            style: GoogleFonts.notoSansBengali(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bloodtype, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'গ্রুপ: ${user?.bloodGroup ?? "N/A"}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (user?.rank != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        user!.rank.toUpperCase(),
                        style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 12),
      child: Text(
        title,
        style: GoogleFonts.notoSansBengali(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.notoSansBengali(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade900),
        ),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.red, fontSize: 11)) : null,
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Blood Donate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFB71C1C))),
              Text('Version 1.0.0', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
          IconButton(
            onPressed: () async {
              // Sign out logic
              await ref.read(userStatusProvider).updateStatus(false);
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.grey),
            tooltip: 'Log Out',
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        title: Text('সহযোগিতা ও মতামত', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'যেকোনো সমস্যায় বা আপনার মূল্যবান মতামত জানাতে আমাদের সাথে যোগাযোগ করুন।',
              style: GoogleFonts.notoSansBengali(fontSize: 14, color: Colors.blueGrey.shade700),
            ),
            const SizedBox(height: 24),
            _buildSupportOption(
              icon: Icons.facebook_rounded,
              title: 'ফেসবুক পেজ',
              subtitle: 'আমাদের ফেসবুক কমিউনিটি',
              color: const Color(0xFF1877F2),
              onTap: () {
                Navigator.pop(context);
                _launchUrl('https://www.facebook.com/blooddonate');
              },
            ),
            const SizedBox(height: 12),
            _buildSupportOption(
              icon: Icons.telegram_rounded,
              title: 'টেলিগ্রাম সাপোর্ট',
              subtitle: 'নম্বর গোপন রেখে মেসেজ দিন',
              color: const Color(0xFF0088cc),
              onTap: () {
                Navigator.pop(context);
                _launchUrl('https://t.me/sn_alam');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('বন্ধ করুন', style: GoogleFonts.notoSansBengali(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                  Text(subtitle, style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.blueGrey.shade600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color.withOpacity(0.5)),
          ],
        ),
      ),
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
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
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
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalProfileScreen())),
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
        _buildNotificationIcon(user.uid),
        _buildChatIcon(user.uid),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNotificationIcon(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').where('isRead', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.where((doc) => (doc.data() as Map<String, dynamic>)['data']?['type'] != 'chat').length;
        }
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()))),
            if (count > 0)
              Positioned(
                right: 8, top: 12,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.yellow.shade700, shape: BoxShape.circle, border: Border.all(color: Colors.red.shade900, width: 1.5)),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(count > 99 ? '99+' : '$count', style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildChatIcon(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('direct_chats').where('participants', arrayContains: uid).snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['unread'] ?? false) == true && data['lastMessageSenderId'] != uid;
          }).length;
        }
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 26), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()))),
            if (count > 0)
              Positioned(
                right: 4, top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.yellow.shade700, shape: BoxShape.circle, border: Border.all(color: Colors.red.shade900, width: 2)),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Center(child: Text(count > 9 ? '9+' : '$count', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold, height: 1), textAlign: TextAlign.center)),
                ),
              ),
          ],
        );
      },
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

  Widget _buildWelcomeSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('আপনার ড্যাশবোর্ড', style: GoogleFonts.notoSansBengali(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 4),
        Text('আজকের রক্তদান একটি জীবন বাঁচাতে পারে', style: GoogleFonts.notoSansBengali(fontSize: 14, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildQuickStats(UserModel user) {
    return Column(
      children: [
        Row(children: [
          _buildStatBox('মোট দান', '${user.totalDonations}', Colors.red, Icons.bloodtype, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen(initialIndex: 2)))),
          const SizedBox(width: 12),
          _buildStatBox('আবেদন', '${user.totalRequests}', Colors.blue, Icons.campaign, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen(initialIndex: 0)))),
          const SizedBox(width: 12),
          _buildStatBox('সেভ করা', '${user.savedDonors.length}', Colors.orange, Icons.favorite, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedDonorsScreen()))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _buildStatBox('ব্যাগ পেয়েছেন', '${user.totalReceivedBags}', Colors.green, Icons.opacity, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen(initialIndex: 1)))),
          const SizedBox(width: 12),
          _buildStatBox('গড় রেটিং', user.averageRating.toStringAsFixed(1), Colors.amber, Icons.star_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewsListScreen(userId: user.uid, userName: user.name)))),
          const SizedBox(width: 12),
          _buildStatBox('বাতিল আবেদন', '${user.totalCancelled}', Colors.blueGrey, Icons.cancel_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen(initialIndex: 3)))),
        ]),
      ],
    );
  }

  Widget _buildStatBox(String title, String value, Color color, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap, borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                Text(title, style: GoogleFonts.notoSansBengali(fontSize: 11, color: Colors.grey.shade600)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveActivitySection(AsyncValue<List<BloodRequestModel>> myReq, AsyncValue<List<BloodRequestModel>> myDon) {
    return myReq.when(
      data: (requests) {
        final reqActive = requests.where((r) => r.status == 'accepted' || r.status == 'donated').toList();
        return myDon.when(
          data: (donations) {
            final donActive = donations.where((r) => r.status == 'accepted' || r.status == 'donated' || r.status == 'completed').toList();
            final others = donActive.where((d) => d.status != 'completed').toList();
            if (reqActive.isEmpty && others.isEmpty) return const SizedBox.shrink();
            return Column(children: [
              ...reqActive.map((req) => _buildActivityCard(req, 'আপনার রক্ত প্রয়োজন', Colors.blue)),
              if (reqActive.isNotEmpty && others.isNotEmpty) const SizedBox(height: 8),
              ...others.map((req) => _buildActivityCard(req, 'আপনি রক্ত দিচ্ছেন', Colors.green)),
              const SizedBox(height: 24),
            ]);
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(title.contains('নিচ্ছেন') ? Icons.volunteer_activism : Icons.history_edu, color: color, size: 22)),
        title: Text(title, style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        subtitle: Text(req.hospitalName, style: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color.withOpacity(0.5)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req))),
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
      decoration: BoxDecoration(gradient: LinearGradient(colors: canDonate ? [Colors.green.shade50, Colors.white] : [Colors.orange.shade50, Colors.white]), borderRadius: BorderRadius.circular(24), border: Border.all(color: canDonate ? Colors.green.shade100 : Colors.orange.shade100)),
      child: Row(children: [
        Icon(canDonate ? Icons.check_circle_rounded : Icons.timer_rounded, color: canDonate ? Colors.green : Colors.orange, size: 28),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(canDonate ? 'আপনি এখন রক্তদান করতে পারবেন' : 'পরবর্তী রক্তদানের সময়', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 16, color: canDonate ? Colors.green.shade900 : Colors.orange.shade900)),
          Text(canDonate ? 'আপনার শেষ রক্তদানের পর ৩ মাস অতিবাহিত হয়েছে।' : 'আর মাত্র $daysLeft দিন পর আপনি আবার রক্তদান করতে পারবেন।', style: GoogleFonts.notoSansBengali(fontSize: 13, color: Colors.blueGrey.shade700)),
        ])),
      ]),
    );
  }

  Widget _buildFactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.shade50)),
      child: Row(children: [
        Icon(Icons.auto_awesome_rounded, color: Colors.blue.shade600, size: 24),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('রক্তদানের টিপস', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue.shade900)),
          Text(_dailyFact, style: GoogleFonts.notoSansBengali(fontSize: 13, color: Colors.blueGrey.shade700, height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: GoogleFonts.notoSansBengali(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      GestureDetector(onTap: onTap, child: Text('সবগুলো দেখুন', style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.bold))),
    ]);
  }

  Widget _buildRequestList(AsyncValue<List<BloodRequestModel>> requestsAsync, UserModel? user) {
    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (requests) {
        if (user == null) return const SizedBox.shrink();
        final filtered = requests.where((r) => r.requesterId != user.uid && r.division.toLowerCase() == (user.address?['division']?.toString().toLowerCase() ?? '')).toList();
        if (filtered.isEmpty) return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text('আপনার বিভাগে কোনো পেন্ডিং আবেদন নেই')));
        
        filtered.sort((a, b) {
          if (a.isEmergency && !b.isEmergency) return -1;
          if (!a.isEmergency && b.isEmergency) return 1;
          return 0;
        });
        return Column(children: filtered.take(3).map((req) => _buildRequestCard(req)).toList());
      },
    );
  }

  Widget _buildRequestCard(BloodRequestModel req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))]),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req))),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Container(width: 56, height: 56, decoration: BoxDecoration(color: req.isEmergency ? Colors.red : Colors.red.shade50, borderRadius: BorderRadius.circular(16)), child: Center(child: Text(req.bloodGroup, style: TextStyle(color: req.isEmergency ? Colors.white : Colors.red, fontWeight: FontWeight.bold, fontSize: 20)))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Text(req.patientName.isEmpty ? 'নামহীন রোগী' : req.patientName, style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 16)), if (req.isEmergency) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(6)), child: Text('জরুরি', style: GoogleFonts.notoSansBengali(color: Colors.white, fontSize: 10)))]]),
                Text(req.hospitalName, style: GoogleFonts.notoSansBengali(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              const Icon(Icons.keyboard_arrow_right_rounded, color: Colors.blue),
            ]),
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [Icon(Icons.location_on_rounded, size: 16, color: Colors.grey.shade400), const SizedBox(width: 4), Text('${req.district}, ${req.thana}', style: GoogleFonts.notoSansBengali(color: Colors.grey.shade600, fontSize: 12))]),
              GestureDetector(onTap: () => _launchMapUrl(req.mapUrl ?? req.hospitalName), child: Text('ম্যাপ দেখুন', style: GoogleFonts.notoSansBengali(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold))),
            ]),
          ]),
        ),
      ),
    );
  }
}
