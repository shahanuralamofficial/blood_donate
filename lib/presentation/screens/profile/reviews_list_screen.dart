import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/blood_request_model.dart';

class ReviewsListScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const ReviewsListScreen({super.key, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: Text(
          '$userName-র রিভিউসমূহ',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blood_requests')
            .where('donorId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          final docs = snapshot.data?.docs ?? [];
          
          // ফিল্টার: যেখানে থ্যাঙ্কস নোট অথবা রিভিউ অন্তত একটি আছে
          final reviews = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final hasNote = data['thankYouNote'] != null && (data['thankYouNote'] as String).trim().isNotEmpty;
            final hasExp = data['donorExperience'] != null && (data['donorExperience'] as String).trim().isNotEmpty;
            return hasNote || hasExp;
          }).toList();

          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text('এখনো কোনো রিভিউ নেই', style: GoogleFonts.notoSansBengali(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final data = reviews[index].data() as Map<String, dynamic>;
              final req = BloodRequestModel.fromMap(data, reviews[index].id);
              final DateTime date = req.createdAt ?? DateTime.now();
              final double rating = (data['donorRating'] ?? 5.0).toDouble();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(5, (i) => Icon(
                            Icons.star_rounded, 
                            color: i < rating ? Colors.orange : Colors.grey.shade200, 
                            size: 20,
                          )),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(date),
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (req.thankYouNote != null && req.thankYouNote!.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.favorite, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              req.thankYouNote!,
                              style: GoogleFonts.notoSansBengali(
                                color: Colors.black87,
                                fontSize: 14,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (data['donorExperience'] != null && (data['donorExperience'] as String).isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data['donorExperience'],
                          style: GoogleFonts.notoSansBengali(
                            color: Colors.blueGrey.shade700,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade100),
                    const SizedBox(height: 4),
                    Text(
                      '— ${req.relationWithPatient} (${req.patientName}-র জন্য)', 
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
