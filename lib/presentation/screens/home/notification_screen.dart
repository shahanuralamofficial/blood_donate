import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/language_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: Text(ref.tr('notifications'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (userId != null)
            IconButton(
              onPressed: () => _markAllAsRead(userId),
              icon: const Icon(Icons.done_all_rounded, color: Colors.red),
              tooltip: ref.tr('mark_all_as_read'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: userId == null 
          ? Center(child: Text(ref.tr('login_required')))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.red));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(ref);
                }

                // চ্যাট বাদে সব নোটিফিকেশন ফিল্টার করা
                final notifications = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final type = data['data']?['type'] ?? 'general';
                  return type != 'chat';
                }).toList();

                if (notifications.isEmpty) {
                  return _buildEmptyState(ref);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildNotificationCard(context, ref, doc.id, userId, data);
                  },
                );
              },
            ),
    );
  }

  void _markAllAsRead(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Widget _buildNotificationCard(BuildContext context, WidgetRef ref, String docId, String userId, Map<String, dynamic> data) {
    final bool isRead = data['isRead'] ?? false;
    final Map<String, dynamic> extraData = data['data'] ?? {};
    final String type = extraData['type'] ?? 'general';
    final DateTime? time = (data['createdAt'] as Timestamp?)?.toDate();

    IconData icon = Icons.notifications_rounded;
    Color iconColor = Colors.blue;

    if (type == 'emergency' || type == 'blood_request') {
      icon = Icons.bloodtype_rounded;
      iconColor = Colors.red;
    } else if (type == 'donation_confirm' || data['title'].toString().contains('রক্ত দিয়েছে')) {
      icon = Icons.volunteer_activism_rounded;
      iconColor = Colors.green;
    } else if (type == 'rank_up' || data['title'].toString().contains('র‍্যাঙ্ক')) {
      icon = Icons.stars_rounded;
      iconColor = Colors.orange;
    }

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').doc(docId).delete();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : Colors.red.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRead ? Colors.grey.shade100 : Colors.red.shade100,
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Read মার্ক করা
              FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').doc(docId).update({'isRead': true});
              
              // নেভিগেশন হ্যান্ডেল করা
              if (extraData['requestId'] != null) {
                Navigator.pushNamed(
                  context, 
                  '/request_details', 
                  arguments: extraData['requestId']
                );
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                data['title'] ?? ref.tr('new_notification'),
                                style: GoogleFonts.notoSansBengali(
                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['body'] ?? '',
                          style: GoogleFonts.notoSansBengali(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              time != null ? DateFormat('hh:mm a, dd MMM').format(time) : '',
                              style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildEmptyState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle),
            child: Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade200),
          ),
          const SizedBox(height: 24),
          Text(
            ref.tr('no_notifications'),
            style: GoogleFonts.notoSansBengali(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            ref.tr('new_updates_will_appear_here'),
            style: GoogleFonts.notoSansBengali(color: Colors.grey.shade300, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
