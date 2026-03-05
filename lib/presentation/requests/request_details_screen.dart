import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/models/blood_request_model.dart';
import '../screens/chat/chat_screen.dart';

class RequestDetailsScreen extends StatelessWidget {
  final BloodRequestModel request;

  const RequestDetailsScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    // যে ইউজার রক্তের জন্য আবেদন করেছেন তার আইডি
    final String targetUserId = request.requesterId;
    final bool isMyRequest = currentUser?.uid == targetUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('আবেদনের বিবরণ', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // আবেদনকারীর প্রোফাইল তথ্য লোড করা
        future: FirebaseFirestore.instance.collection('users').doc(targetUserId).get(),
        builder: (context, snapshot) {
          String name = 'ব্যবহারকারী';
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            name = data['name'] ?? name;
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // কার্ডে ইউজারের নাম দেখানো হচ্ছে
                _buildInfoCard(isMyRequest ? 'আপনি নিজে' : name),
                const SizedBox(height: 24),
                
                // চ্যাট বাটন: সরাসরি ইউজারের নাম সহ (যদি ইউজার আপনি নিজে না হন)
                if (currentUser != null && !isMyRequest)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // ইউনিক চ্যাট আইডি তৈরি (direct_uidA_uidB)
                        List<String> ids = [currentUser.uid, targetUserId];
                        ids.sort();
                        final chatId = 'direct_${ids[0]}_${ids[1]}';

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              requestId: chatId,
                              otherUserName: name, // সরাসরি আসল নাম
                              otherUserId: targetUserId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: Text('$name-এর সাথে চ্যাট করুন', 
                        style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
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

  Widget _buildInfoCard(String userName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildDetailRow('নাম', userName),
          _buildDetailRow('রক্তের গ্রুপ', request.bloodGroup, isHighlight: true),
          _buildDetailRow('ব্যাগ সংখ্যা', '${request.bloodBags} ব্যাগ'),
          _buildDetailRow('হাসপাতাল', request.hospitalName),
          _buildDetailRow('রোগীর নাম', request.patientName),
          _buildDetailRow('তারিখ', request.requiredDate != null ? DateFormat('dd MMMM, yyyy').format(request.requiredDate!) : 'জরুরি'),
          _buildDetailRow('যোগাযোগ', request.phoneNumber),
          if (request.description.isNotEmpty)
            _buildDetailRow('বিবরণ', request.description),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.notoSansBengali(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(value, 
              textAlign: TextAlign.end,
              style: GoogleFonts.notoSansBengali(
                fontWeight: FontWeight.bold,
                color: isHighlight ? Colors.red : Colors.black87,
                fontSize: isHighlight ? 20 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
