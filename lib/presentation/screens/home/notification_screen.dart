import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: Text('নোটিফিকেশন', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (userId != null)
            TextButton(
              onPressed: () => _markAllAsRead(userId),
              child: Text('সবগুলো পড়া হয়েছে', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: userId == null 
          ? const Center(child: Text('লগইন প্রয়োজন'))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.red));
                
                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                final userThana = userData?['address']?['thana']?.toString().toLowerCase();
                final userDistrict = userData?['address']?['district']?.toString().toLowerCase();

                return StreamBuilder<QuerySnapshot>(
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
                      return _buildEmptyState();
                    }

                    // স্মার্ট ফিল্টারিং লজিক
                    final notifications = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final type = data['data']?['type'] ?? 'general';
                      
                      // ১. চ্যাট নোটিফিকেশন লিস্টে দেখাবে না
                      if (type == 'chat') return false;

                      // ২. র‍্যাঙ্ক আপডেট সংক্রান্ত হলে দেখাবে
                      if (type == 'rank_up' || (data['title']?.toString().contains('র‍্যাঙ্ক') ?? false)) return true;

                      // ৩. ব্লাড রিকোয়েস্ট হলে নিজ থানা/জেলা চেক করবে
                      if (type == 'emergency' || (data['title']?.toString().contains('রক্ত') ?? false)) {
                        final reqThana = data['data']?['thana']?.toString().toLowerCase();
                        final reqDistrict = data['data']?['district']?.toString().toLowerCase();
                        
                        // যদি থানা বা জেলা মিলে যায় তবে দেখাবে
                        return (reqThana != null && reqThana == userThana) || 
                               (reqDistrict != null && reqDistrict == userDistrict);
                      }

                      return true; // অন্যান্য সাধারণ নোটিফিকেশন দেখাবে
                    }).toList();

                    if (notifications.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final doc = notifications[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildNotificationCard(context, doc.id, userId, data);
                      },
                    );
                  },
                );
              }
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

  Widget _buildNotificationCard(BuildContext context, String docId, String userId, Map<String, dynamic> data) {
    final bool isRead = data['isRead'] ?? false;
    final String type = data['data']?['type'] ?? 'general';
    final DateTime? time = (data['createdAt'] as Timestamp?)?.toDate();

    IconData icon = Icons.notifications_rounded;
    Color iconColor = Colors.blue;

    if (type == 'emergency') {
      icon = Icons.bloodtype_rounded;
      iconColor = Colors.red;
    } else if (type == 'chat') {
      icon = Icons.chat_bubble_rounded;
      iconColor = Colors.green;
    } else if (data['title'].toString().contains('ধন্যবাদ') || data['title'].toString().contains('সফল')) {
      icon = Icons.favorite_rounded;
      iconColor = Colors.pink;
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
          color: isRead ? Colors.white : const Color(0xFFFFEBEE).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRead ? Colors.grey.shade100 : Colors.red.shade100,
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').doc(docId).update({'isRead': true});
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
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
                                data['title'] ?? 'নতুন নোটিফিকেশন',
                                style: GoogleFonts.notoSansBengali(
                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['body'] ?? '',
                          style: GoogleFonts.notoSansBengali(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              time != null ? DateFormat('hh:mm a, dd MMM').format(time) : '',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
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

  Widget _buildEmptyState() {
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
            'এখনো কোনো নোটিফিকেশন নেই',
            style: GoogleFonts.notoSansBengali(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'নতুন কোনো আপডেট এলে এখানে দেখতে পাবেন।',
            style: GoogleFonts.notoSansBengali(color: Colors.grey.shade300, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
