import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ReviewsListScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const ReviewsListScreen({super.key, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: Text('$userName-র রিভিউসমূহ', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // In a real app, reviews would be stored in a separate collection or subcollection
        // For this demo, we'll try to find them or show a placeholder if not found
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('donorId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final data = reviews[index].data() as Map<String, dynamic>;
              final double rating = (data['rating'] ?? 5.0).toDouble();
              final DateTime date = (data['createdAt'] as Timestamp).toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
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
                            size: 18,
                          )),
                        ),
                        Text(DateFormat('dd MMM yyyy').format(date), style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['comment'] ?? 'কোনো মন্তব্য নেই।',
                      style: GoogleFonts.notoSansBengali(color: Colors.blueGrey.shade800, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text('— গ্রহীতা', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
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
