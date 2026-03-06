import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
            data: (user) => user != null ? Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.red),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(user: user))),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.grey),
                  onPressed: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('লগআউট'),
                        content: const Text('আপনি কি নিশ্চিতভাবে লগআউট করতে চান?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('না')),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('হ্যাঁ', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true) {
                      // প্রথমে অফলাইন স্ট্যাটাস আপডেট করা
                      await ref.read(userStatusProvider).updateStatus(false);
                      // তারপর লগআউট করা
                      await FirebaseAuth.instance.signOut();
                    }
                  },
                ),
              ],
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
                      _buildDangerZone(context, ref, user),
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

  Widget _buildDangerZone(BuildContext context, WidgetRef ref, UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ডেঞ্জার জোন',
            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red.shade900),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.delete_forever_rounded,
            'অ্যাকাউন্ট মুছে ফেলুন',
            'আপনার সকল তথ্য স্থায়ীভাবে মুছে যাবে',
            Colors.red,
            onTap: () => _showDeleteAccountDialog(context, ref, user),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref, UserModel user) {
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('অ্যাকাউন্ট মুছে ফেলবেন?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'নিরাপত্তার স্বার্থে আপনার পাসওয়ার্ডটি পুনরায় প্রদান করুন। আপনার সকল তথ্য চিরতরে মুছে যাবে।',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'আপনার পাসওয়ার্ড',
                  hintText: 'পাসওয়ার্ড লিখুন',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('না'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('পাসওয়ার্ড প্রয়োজন')));
                  return;
                }

                setState(() => isLoading = true);

                try {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null && currentUser.email != null) {
                    // ১. পাসওয়ার্ড দিয়ে পুনরায় অথেন্টিকেট করা
                    final credential = EmailAuthProvider.credential(
                      email: currentUser.email!,
                      password: passwordController.text,
                    );
                    await currentUser.reauthenticateWithCredential(credential);

                    // ২. স্ট্যাটাস অফলাইন করা
                    await ref.read(userStatusProvider).updateStatus(false);

                    // ৩. ডাটাবেস থেকে ইউজার ডকুমেন্ট ডিলিট করা
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

                    // ৪. ফায়ারবেস অথ থেকে ইউজার ডিলিট করা
                    await currentUser.delete();

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('অ্যাকাউন্টটি সফলভাবে মুছে ফেলা হয়েছে')),
                      );
                    }
                  }
                } on FirebaseAuthException catch (e) {
                  setState(() => isLoading = false);
                  String message = 'কিছু ভুল হয়েছে';
                  if (e.code == 'wrong-password') message = 'ভুল পাসওয়ার্ড!';
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                } catch (e) {
                  setState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('একটি সমস্যা হয়েছে। আবার চেষ্টা করুন।')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('হ্যাঁ, মুছে ফেলুন'),
            ),
          ],
        ),
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
