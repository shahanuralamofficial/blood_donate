import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    // চেক করা হচ্ছে এটি কি বর্তমান ইউজারের নিজের প্রোফাইল কি না
    final bool isOwnProfile = FirebaseAuth.instance.currentUser?.uid == userId;

    return DefaultTabController(
      length: isOwnProfile ? 2 : 1, // নিজের হলে ২টি ট্যাব, অন্যের হলে ১টি
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFB),
        appBar: AppBar(
          title: Text(
            isOwnProfile ? 'আমার রিভিউ ও বার্তা' : '$userName-র রিভিউসমূহ',
            style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          bottom: TabBar(
            labelColor: Colors.red,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.red,
            labelStyle: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              const Tab(text: 'রিভিউ ও রেটিং'),
              if (isOwnProfile) const Tab(text: 'ধন্যবাদ বার্তা'),
            ],
          ),
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
            
            return TabBarView(
              children: [
                _buildReviewsTab(docs),
                if (isOwnProfile) _buildThanksTab(docs),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReviewsTab(List<QueryDocumentSnapshot> docs) {
    final reviews = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['donorExperience'] != null && (data['donorExperience'] as String).trim().isNotEmpty;
    }).toList();

    if (reviews.isEmpty) {
      return _buildEmptyState(Icons.star_outline_rounded, 'কোনো রিভিউ পাওয়া যায়নি');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final data = reviews[index].data() as Map<String, dynamic>;
        final req = BloodRequestModel.fromMap(data, reviews[index].id);
        final double rating = (data['donorRating'] ?? 5.0).toDouble();

        return _buildCard(
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
                  Text(
                    DateFormat('dd MMM yyyy').format(req.createdAt ?? DateTime.now()),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data['donorExperience'],
                style: GoogleFonts.notoSansBengali(
                  color: Colors.blueGrey.shade800,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildFooter(req),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThanksTab(List<QueryDocumentSnapshot> docs) {
    final thanks = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['thankYouNote'] != null && (data['thankYouNote'] as String).trim().isNotEmpty;
    }).toList();

    if (thanks.isEmpty) {
      return _buildEmptyState(Icons.favorite_border_rounded, 'কোনো ধন্যবাদ বার্তা নেই');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: thanks.length,
      itemBuilder: (context, index) {
        final data = thanks[index].data() as Map<String, dynamic>;
        final req = BloodRequestModel.fromMap(data, thanks[index].id);

        return _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 20),
                  Text(
                    DateFormat('dd MMM yyyy').format(req.createdAt ?? DateTime.now()),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                req.thankYouNote!,
                style: GoogleFonts.notoSansBengali(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildFooter(req),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildFooter(BloodRequestModel req) {
    return Column(
      children: [
        Divider(color: Colors.grey.shade100),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.person_outline, size: 12, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${req.relationWithPatient} (${req.patientName}-র জন্য)', 
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.notoSansBengali(color: Colors.grey)),
        ],
      ),
    );
  }
}
