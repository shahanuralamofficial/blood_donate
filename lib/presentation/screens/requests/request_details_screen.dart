import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blood_request_provider.dart';
import '../../providers/language_provider.dart';
import '../chat/chat_screen.dart';
import '../donors/donor_public_profile_screen.dart';

class RequestDetailsScreen extends ConsumerStatefulWidget {
  final BloodRequestModel? request;
  final String? requestId;

  const RequestDetailsScreen({super.key, this.request, this.requestId});

  @override
  ConsumerState<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends ConsumerState<RequestDetailsScreen> {
  bool _celebrationShown = false;

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Call Error: $e");
    }
  }

  Future<void> _openMap(String? address) async {
    if (address == null || address.isEmpty) return;
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

  Future<void> _openWhatsApp(String phoneNumber) async {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
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

  void _navigateToDonorProfile(BuildContext context, String donorId) async {
    final donorDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(donorId)
        .get();
    if (donorDoc.exists && context.mounted) {
      final donorUser = UserModel.fromMap(donorDoc.data()!);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DonorPublicProfileScreen(donor: donorUser),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String targetId = widget.requestId ?? widget.request?.requestId ?? '';
    final liveRequestAsync = ref.watch(
      requestStreamByIdProvider(targetId),
    );
    final userAsync = ref.watch(currentUserDataProvider);
    final user = userAsync.value;

    // অভিনন্দন লজিক
    userAsync.whenData((userData) {
      if (userData != null && userData.rankUpdatePending && !_celebrationShown) {
        _celebrationShown = true;
        // আপডেট শেষ করে দিচ্ছি যাতে বারবার না আসে
        FirebaseFirestore.instance.collection('users').doc(userData.uid).update({
          'rankUpdatePending': false,
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showCelebrationDialog(userData.rank);
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: Text(
          ref.tr('request_details'),
          style: GoogleFonts.notoSansBengali(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: liveRequestAsync.when(
        data: (liveRequest) {
          final isRequester = user?.uid == liveRequest.requesterId;
          final isDonor = user?.uid == liveRequest.donorId;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusSection(liveRequest.status),
                const SizedBox(height: 24),
                if (liveRequest.status == 'accepted' && liveRequest.donorId != null)
                  _buildAcceptedDonorInfo(liveRequest),
                _buildProgressCard(liveRequest),
                const SizedBox(height: 20),
                _buildInfoCard(liveRequest),
                const SizedBox(height: 24),
                _buildContactCard(context, isRequester, liveRequest, user),
                const SizedBox(height: 32),

                if (!isRequester && liveRequest.status == 'pending')
                  ElevatedButton(
                    onPressed: () => _showAcceptDonationDialog(
                      context,
                      ref,
                      liveRequest,
                      user!.uid,
                      user.name,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      ref.tr('accept_donation'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                if (isDonor && liveRequest.status == 'accepted')
                  ElevatedButton(
                    onPressed: () => _showDonorDonatedDialog(
                      context,
                      ref,
                      liveRequest,
                      user,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      ref.tr('i_donated'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                if (isRequester &&
                    (liveRequest.status == 'accepted' ||
                        liveRequest.status == 'donated'))
                  Column(
                    children: [
                      if (liveRequest.status == 'donated')
                        _buildStatusAlert(
                          ref.tr('donor_reported_donated'),
                        ),
                      ElevatedButton(
                        onPressed: () => _showConfirmBloodDialog(
                          context,
                          ref,
                          liveRequest,
                          user!.name,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          ref.tr('i_received'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () =>
                            _showNotReceivedDialog(context, ref, liveRequest),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          ref.tr('i_didnt_receive'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                if (isRequester &&
                    (liveRequest.status == 'pending' ||
                        liveRequest.status == 'accepted'))
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Center(
                      child: TextButton(
                        onPressed: () => _showCancelDialog(
                          context,
                          ref,
                          liveRequest.requestId,
                          liveRequest.requesterId,
                        ),
                        child: Text(
                          ref.tr('cancel_request'),
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (liveRequest.status == 'completed')
                  _buildSuccessMessage(liveRequest),
              ],
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.red)),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showCelebrationDialog(String rank) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.stars_rounded, color: Colors.amber, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ref.tr('congratulations'),
              style: GoogleFonts.notoSansBengali(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ref.tr('rank_update_message'),
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
                '${ref.tr('rank')}: $rank',
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
            child: Text(ref.tr('ok')),
          ),
        ],
      ),
    );
  }

  void _showDonorDonatedDialog(
    BuildContext context,
    WidgetRef ref,
    BloodRequestModel req,
    UserModel? donor,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(ref.tr('confirm_donation_title')),
        content: Text(
          ref.tr('confirm_donation_msg'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.tr('no')),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(bloodRequestRepositoryProvider)
                  .updateRequestStatus(
                    req.requestId,
                    'donated',
                  );

              NotificationService().sendNotificationToUser(
                receiverId: req.requesterId,
                title: ref.tr('donation_update'),
                body: ref.tr('donor_reported_donated_msg')
                    .replaceFirst('{}', donor?.name ?? ref.tr('donor')),
                data: {
                  'type': 'donation_confirm',
                  'requestId': req.requestId,
                },
              );

              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ref.tr('thank_you_donating')),
                  ),
                );
                Navigator.pop(context); // Go back
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(ref.tr('yes_donated'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAcceptDonationDialog(
    BuildContext context,
    WidgetRef ref,
    BloodRequestModel req,
    String donorId,
    String donorName,
  ) {
    int bagsToDonate = 1;
    String donationType = 'self'; // 'self' or 'arranged'
    int remainingBags = req.bloodBags - req.donatedBags;
    if (remainingBags <= 0) remainingBags = 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(ref.tr('accept_donation')),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ref.tr('how_many_bags_donate').replaceFirst('{}', req.patientName)),
              const SizedBox(height: 12),
              DropdownButton<int>(
                value: bagsToDonate,
                isExpanded: true,
                items: List.generate(remainingBags, (index) => index + 1)
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e, child: Text('$e ${ref.tr('bag_count')}')),
                    )
                    .toList(),
                onChanged: (v) => setState(() => bagsToDonate = v!),
              ),
              const SizedBox(height: 20),
              Text(
                ref.tr('donation_type'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              RadioListTile<String>(
                title: Text(ref.tr('will_donate_myself')),
                value: 'self',
                groupValue: donationType,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => donationType = v!),
              ),
              RadioListTile<String>(
                title: Text(ref.tr('will_manage_donor')),
                value: 'arranged',
                groupValue: donationType,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => donationType = v!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('blood_requests')
                  .doc(req.requestId)
                  .update({
                'donorId': donorId,
                'status': 'accepted',
                'donationType': donationType,
                'acceptedBags': bagsToDonate,
              });

              NotificationService().sendNotificationToUser(
                receiverId: req.requesterId,
                title: ref.tr('donor_found'),
                body: donationType == 'self'
                    ? ref.tr('donor_accepted_msg')
                        .replaceFirst('{}', donorName)
                        .replaceFirst('{}', bagsToDonate.toString())
                        .replaceFirst('{}', ref.tr('personally'))
                    : ref.tr('donor_accepted_msg')
                        .replaceFirst('{}', donorName)
                        .replaceFirst('{}', bagsToDonate.toString())
                        .replaceFirst('{}', ref.tr('by_managing')),
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ref.tr('thank_you_donating')),
                  ),
                );
              }
            },
            child: Text(ref.tr('yes')),
          ),
        ],
      ),
    );
  }

  void _showConfirmBloodDialog(
    BuildContext context,
    WidgetRef ref,
    BloodRequestModel req,
    String requesterName,
  ) {
    int receivedBags = 1;
    String donationType = req.donationType ?? 'self';
    final thankYouController = TextEditingController();
    int maxCanReceive = req.bloodBags - req.donatedBags;
    if (maxCanReceive <= 0) maxCanReceive = 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          ref.tr('confirm_donation_title'),
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.tr('how_many_bags_received'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                DropdownButton<int>(
                  value: receivedBags,
                  isExpanded: true,
                  items: List.generate(maxCanReceive, (index) => index + 1)
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e, child: Text('$e ${ref.tr('bag_count')}')),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => receivedBags = v!),
                ),
                const SizedBox(height: 16),
                Text(
                  ref.tr('did_donor_donate_self'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                RadioListTile<String>(
                  title: Text(ref.tr('donated_self')),
                  value: 'self',
                  groupValue: donationType,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => donationType = v!),
                ),
                RadioListTile<String>(
                  title: Text(ref.tr('donated_managed')),
                  value: 'arranged',
                  groupValue: donationType,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => donationType = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: thankYouController,
                  decoration: InputDecoration(
                    labelText: ref.tr('write_thank_you'),
                    hintText: '...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.tr('later')),
          ),
          ElevatedButton(
            onPressed: () async {
              int totalDonated = req.donatedBags + receivedBags;
              bool isFullyCompleted = totalDonated >= req.bloodBags;
              String newStatus = isFullyCompleted ? 'completed' : 'pending';

              WriteBatch batch = FirebaseFirestore.instance.batch();
              DocumentReference reqRef = FirebaseFirestore.instance
                  .collection('blood_requests')
                  .doc(req.requestId);

              // ১. ব্লাড রিকোয়েস্ট আপডেট
              batch.update(reqRef, {
                'donatedBags': totalDonated,
                'status': newStatus,
                'thankYouNote': thankYouController.text.trim(),
                'donorId': req.donorId,
                'donationType': donationType,
                'completedAt': FieldValue.serverTimestamp(),
              });

              if (req.donorId != null) {
                final donorDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(req.donorId)
                    .get();

                if (donorDoc.exists) {
                  final donorData = donorDoc.data()!;
                  int currentDonations = donorData['totalDonations'] ?? 0;
                  
                  if (donationType == 'self') {
                    int newTotalDonations = currentDonations + receivedBags;
                    String newRank = 'Newbie';
                    List<String> newBadges = List<String>.from(donorData['badges'] ?? []);
                    
                    if (newTotalDonations >= 50) newRank = 'Diamond';
                    else if (newTotalDonations >= 30) newRank = 'Platinum';
                    else if (newTotalDonations >= 15) newRank = 'Gold';
                    else if (newTotalDonations >= 5) newRank = 'Silver';
                    else if (newTotalDonations >= 1) newRank = 'Bronze';

                    if (newRank != 'Newbie' && !newBadges.contains(newRank)) {
                      newBadges.add(newRank);
                    }

                    batch.update(
                      FirebaseFirestore.instance.collection('users').doc(req.donorId),
                      {
                        'totalDonations': newTotalDonations,
                        'rank': newRank,
                        'badges': newBadges,
                        'rankUpdatePending': true,
                        'lastDonationDate': FieldValue.serverTimestamp(),
                      },
                    );
                  }
                }

                NotificationService().sendNotificationToUser(
                  receiverId: req.donorId!,
                  title: ref.tr('donation_completed_title'),
                  body: ref.tr('recipient_confirmed_msg')
                      .replaceFirst('{}', requesterName)
                      .replaceFirst('{}', receivedBags.toString()),
                );
              }

              batch.update(
                FirebaseFirestore.instance.collection('users').doc(req.requesterId),
                {
                  'totalReceived': isFullyCompleted ? FieldValue.increment(1) : FieldValue.increment(0),
                  'totalReceivedBags': FieldValue.increment(receivedBags),
                },
              );

              await batch.commit();
              
              if (context.mounted) {
                Navigator.pop(context); // ক্লোজ কনফার্ম ডায়ালগ
                // যদি দাতা থাকে, তবেই রিভিউ ডায়ালগ দেখাবে
                if (req.donorId != null) {
                  _showReviewDialog(context, req.donorId!, req.requestId);
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ref.tr('completed'))),
                  );
                }
              }
            },
            child: Text(ref.tr('yes')),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, String donorId, String requestId) {
    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          ref.tr('rate_donor_title'),
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ref.tr('rate_donor_msg'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => rating = index + 1.0),
                    child: Icon(
                      index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 38,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: ref.tr('write_experience'),
                hintText: ref.tr('donor_hint'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (donorId.isNotEmpty) {
                final donorRef = FirebaseFirestore.instance.collection('users').doc(donorId);
                
                await FirebaseFirestore.instance.runTransaction((transaction) async {
                  final snapshot = await transaction.get(donorRef);
                  if (snapshot.exists) {
                    double currentRating = (snapshot.data()?['averageRating'] ?? 5.0).toDouble();
                    int totalReviews = (snapshot.data()?['totalReviews'] ?? 0) + 1;
                    double newRating = ((currentRating * (totalReviews - 1)) + rating) / totalReviews;
                    
                    transaction.update(donorRef, {
                      'averageRating': newRating,
                      'totalReviews': totalReviews,
                    });
                  }
                });
                
                await FirebaseFirestore.instance.collection('blood_requests').doc(requestId).update({
                  'donorExperience': commentController.text.trim(),
                  'donorRating': rating,
                  'reviewedAt': FieldValue.serverTimestamp(),
                });
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ref.tr('review_save_success'))),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(ref.tr('submit')),
          ),
        ],
      ),
    );
  }

  void _showNotReceivedDialog(
    BuildContext context,
    WidgetRef ref,
    BloodRequestModel req,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ref.tr('not_received_title')),
        content: Text(ref.tr('not_received_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('blood_requests')
                  .doc(req.requestId)
                  .update({'status': 'pending', 'donorId': null});
              if (req.donorId != null) {
                NotificationService().sendNotificationToUser(
                  receiverId: req.donorId!,
                  title: ref.tr('donation_update'),
                  body: ref.tr('recipient_reported_not_received_msg'),
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(ref.tr('yes')),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    String requestId,
    String requesterId,
  ) {
    String? selectedReason;
    final reasons = [
      ref.tr('reason_received'),
      ref.tr('reason_patient_passed'),
      ref.tr('reason_other')
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(ref.tr('cancel_request_title')),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ref.tr('cancel_request_msg')),
              const SizedBox(height: 16),
              ...reasons.map(
                (r) => RadioListTile<String>(
                  title: Text(r),
                  value: r,
                  groupValue: selectedReason,
                  onChanged: (v) => setState(() => selectedReason = v),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.tr('no')),
          ),
          TextButton(
            onPressed: () async {
              if (selectedReason == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ref.tr('select_info')),
                  ),
                );
                return;
              }
              await FirebaseFirestore.instance
                  .collection('blood_requests')
                  .doc(requestId)
                  .update({
                    'status': 'cancelled',
                    'cancelReason': selectedReason,
                  });
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(requesterId)
                  .update({'totalCancelled': FieldValue.increment(1)});
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: Text(
              ref.tr('yes'),
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(String status) {
    Color color = Colors.orange;
    if (status == 'accepted') color = Colors.blue;
    if (status == 'donated') color = Colors.purple;
    if (status == 'completed') color = Colors.green;
    if (status == 'cancelled') color = Colors.red;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(BloodRequestModel req) {
    double progress = req.bloodBags > 0 ? (req.donatedBags / req.bloodBags) : 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ref.tr('rank_progress'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${req.donatedBags}/${req.bloodBags} ${ref.tr('bag_count')}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: Colors.red,
              backgroundColor: Colors.red.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BloodRequestModel req) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          _buildRow(ref.tr('patient_name_opt'), req.patientName, isBold: true),
          const Divider(height: 24),
          _buildRow(
            ref.tr('blood_group'),
            req.bloodGroup,
            isBold: true,
            color: Colors.red,
          ),
          const Divider(height: 24),
          _buildRow(ref.tr('hospital_name'), req.hospitalName),
          const SizedBox(height: 12),
          _buildRow(ref.tr('district'), req.district),
          const SizedBox(height: 12),
          _buildRow(
            ref.tr('date'),
            DateFormat(
              'dd MMM yyyy',
              ref.watch(languageProvider).languageCode,
            ).format(req.requiredDate ?? DateTime.now()),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    bool isRequester,
    BloodRequestModel req,
    UserModel? user,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: Colors.red),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRequester && req.donorId != null
                          ? ref.tr('contact_donor')
                          : ref.tr('contact_requester'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: req.donorId != null
                          ? () => _navigateToDonorProfile(context, req.donorId!)
                          : null,
                      child: Text(
                        isRequester && req.donorId != null
                            ? ref.tr('view_profile')
                            : req.phoneNumber,
                        style: TextStyle(
                          color: isRequester && req.donorId != null
                              ? Colors.blue
                              : Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: isRequester && req.donorId != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                          decoration: isRequester && req.donorId != null
                              ? TextDecoration.underline
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  onTap: () => _makePhoneCall(req.phoneNumber),
                  icon: Icons.call_rounded,
                  label: ref.tr('call'),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildContactButton(
                  onTap: () =>
                      _openWhatsApp(req.whatsappNumber ?? req.phoneNumber),
                  icon: FontAwesomeIcons.whatsapp,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  isFontAwesome: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildContactButton(
                  onTap: () {
                    if (user == null) return;
                    
                    // যার সাথে চ্যাট হবে তার আইডি (আবেদনকারী অথবা দাতা)
                    final String otherId = isRequester && req.donorId != null 
                        ? req.donorId! 
                        : req.requesterId;
                    
                    final String otherName = isRequester && req.donorId != null
                        ? ref.tr('donor')
                        : req.patientName;

                    // আইডি দুটিকে বর্ণানুক্রমিকভাবে সাজিয়ে ইউনিক চ্যাট আইডি তৈরি
                    List<String> ids = [user.uid, otherId];
                    ids.sort();
                    final chatId = 'direct_${ids[0]}_${ids[1]}';
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          requestId: chatId,
                          otherUserName: otherName,
                          otherUserId: otherId,
                          requestMention: '${ref.tr('patient_name_unknown')}: ${req.patientName} (${req.bloodGroup})',
                        ),
                      ),
                    );
                  },
                  icon: Icons.chat_bubble_rounded,
                  label: ref.tr('chat'),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildContactButton(
                  onTap: () => _openMap(req.mapUrl ?? req.hospitalName),
                  icon: Icons.map_rounded,
                  label: ref.tr('map'),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
    bool isFontAwesome = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            isFontAwesome
                ? FaIcon(icon, color: color, size: 20)
                : Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusAlert(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedDonorInfo(BloodRequestModel req) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(req.donorId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final donorData = snapshot.data!.data() as Map<String, dynamic>;
          final donorName = donorData['name'] ?? ref.tr('a_donor');
          final acceptedBags = req.acceptedBags ?? 1;
          final type = req.donationType == 'arranged' ? ref.tr('by_managing') : ref.tr('personally');
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ref.tr('donor_accepted_msg')
                        .replaceFirst('{}', donorName)
                        .replaceFirst('{}', acceptedBags.toString())
                        .replaceFirst('{}', type),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSuccessMessage(BloodRequestModel req) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 60),
              const SizedBox(height: 16),
              Text(
                ref.tr('donation_success_title'),
                style: GoogleFonts.notoSansBengali(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ref.tr('donation_success_msg'),
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansBengali(
                  fontSize: 13,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
        ),
        if (req.thankYouNote != null && req.thankYouNote!.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildNoteCard(req.thankYouNote!, ref.tr('from_recipient_thanks')),
        ],
        if (req.donorExperience != null &&
            req.donorExperience!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildNoteCard(req.donorExperience!, ref.tr('from_donor_experience')),
        ],
      ],
    );
  }

  Widget _buildNoteCard(String note, String author) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.format_quote_rounded,
            color: Colors.green,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            note,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansBengali(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.blueGrey.shade800,
              height: 1.5,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            '— $author',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
              color: color ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
