import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/user_model.dart';
import '../chat/chat_screen.dart';
import '../donors/donor_public_profile_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Scaffold(body: Center(child: Text('লগইন প্রয়োজন')));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: Text('মেসেজ লিস্ট', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: _buildSearchBar(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blood_requests')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          var chatRequests = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isRelated = data['requesterId'] == currentUser.uid || data['donorId'] == currentUser.uid;
            final isAccepted = ['accepted', 'donated', 'completed'].contains(data['status']);
            return isRelated && isAccepted;
          }).toList();

          chatRequests.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final timeA = dataA['lastMessageTime'] ?? dataA['createdAt'] ?? Timestamp.now();
            final timeB = dataB['lastMessageTime'] ?? dataB['createdAt'] ?? Timestamp.now();
            return (timeB as Timestamp).compareTo(timeA as Timestamp);
          });

          if (chatRequests.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: chatRequests.length,
            itemBuilder: (context, index) {
              final req = chatRequests[index];
              final data = req.data() as Map<String, dynamic>;
              final isCurrentUserRequester = data['requesterId'] == currentUser.uid;
              
              // চ্যাটের অন্য প্রান্তের ইউজারের আইডি
              final otherUserId = isCurrentUserRequester ? data['donorId'] : data['requesterId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox.shrink();
                  
                  final otherUserData = userSnap.data!.data() as Map<String, dynamic>?;
                  if (otherUserData == null) return const SizedBox.shrink();
                  
                  final otherUser = UserModel.fromMap(otherUserData);
                  final hospitalName = (data['hospitalName'] ?? '').toString();
                  final status = data['status'] ?? '';

                  if (_searchQuery.isNotEmpty && 
                      !otherUser.name.toLowerCase().contains(_searchQuery.toLowerCase()) && 
                      !hospitalName.toLowerCase().contains(_searchQuery.toLowerCase())) {
                    return const SizedBox.shrink();
                  }

                  return _buildChatCard(context, req.id, otherUser, hospitalName, status, isCurrentUserRequester);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'নাম বা হাসপাতালের নাম দিয়ে খুঁজুন...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildChatCard(BuildContext context, String requestId, UserModel otherUser, String hospital, String status, bool isRequester) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DonorPublicProfileScreen(donor: otherUser))),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.red.shade50,
                backgroundImage: otherUser.profileImageUrl != null ? NetworkImage(otherUser.profileImageUrl!) : null,
                child: otherUser.profileImageUrl == null ? const Icon(Icons.person_rounded, color: Colors.red) : null,
              ),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.stars_rounded, color: Colors.amber.shade700, size: 16),
                ),
              ),
            ],
          ),
        ),
        title: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DonorPublicProfileScreen(donor: otherUser))),
          child: Row(
            children: [
              Expanded(child: Text(otherUser.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              _buildStatusChip(status),
            ],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(hospital, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(isRequester ? 'আপনার রক্তদাতা' : 'রক্তের আবেদনকারী', style: TextStyle(color: Colors.red.shade300, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chat_bubble_rounded, color: Colors.blue, size: 24),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(requestId: requestId, otherUserName: otherUser.name))),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;
    if (status == 'accepted') color = Colors.blue;
    if (status == 'donated') color = Colors.purple;
    if (status == 'completed') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text('এখনো কোন চ্যাট শুরু হয়নি', style: GoogleFonts.notoSansBengali(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
