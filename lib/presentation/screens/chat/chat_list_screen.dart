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

          // ১. ইউজারের সাথে সম্পর্কিত সকল এক্সেপ্টেড রিকোয়েস্ট খুঁজে বের করা
          var allRequests = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isRelated = data['requesterId'] == currentUser.uid || data['donorId'] == currentUser.uid;
            final isAccepted = ['accepted', 'donated', 'completed'].contains(data['status']);
            return isRelated && isAccepted;
          }).toList();

          // ২. ইউজার আইডি অনুযায়ী চ্যাটগুলো মার্জ করা (যাতে একই ইউজারের সাথে একাধিক চ্যাট না দেখায়)
          Map<String, dynamic> uniqueChats = {};
          for (var doc in allRequests) {
            final data = doc.data() as Map<String, dynamic>;
            final otherUserId = data['requesterId'] == currentUser.uid ? data['donorId'] : data['requesterId'];
            
            if (otherUserId != null) {
              // যদি আগে থেকেই এই ইউজারের সাথে চ্যাট থাকে, তবে লেটেস্টটা রাখা
              if (!uniqueChats.containsKey(otherUserId)) {
                uniqueChats[otherUserId] = {
                  'requestId': doc.id,
                  'otherUserId': otherUserId,
                  'hospitalName': data['hospitalName'],
                  'status': data['status'],
                  'time': data['lastMessageTime'] ?? data['createdAt'] ?? Timestamp.now(),
                };
              }
            }
          }

          var chatList = uniqueChats.values.toList();
          chatList.sort((a, b) => (b['time'] as Timestamp).compareTo(a['time'] as Timestamp));

          if (chatList.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: chatList.length,
            itemBuilder: (context, index) {
              final chat = chatList[index];
              
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(chat['otherUserId']).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox.shrink();
                  
                  final otherUserData = userSnap.data!.data() as Map<String, dynamic>?;
                  if (otherUserData == null) return const SizedBox.shrink();
                  
                  final otherUser = UserModel.fromMap(otherUserData);

                  if (_searchQuery.isNotEmpty && 
                      !otherUser.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
                    return const SizedBox.shrink();
                  }

                  return _buildChatCard(context, chat['requestId'], otherUser, chat['hospitalName'], chat['status']);
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
          hintText: 'নাম দিয়ে চ্যাট খুঁজুন...',
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

  Widget _buildChatCard(BuildContext context, String requestId, UserModel otherUser, String hospital, String status) {
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
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.red.shade50,
            backgroundImage: otherUser.profileImageUrl != null ? NetworkImage(otherUser.profileImageUrl!) : null,
            child: otherUser.profileImageUrl == null ? const Icon(Icons.person_rounded, color: Colors.red) : null,
          ),
        ),
        title: Text(otherUser.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(hospital, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('র‍্যাঙ্ক: ${otherUser.rank}', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chat_bubble_rounded, color: Colors.blue, size: 24),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(requestId: requestId, otherUserName: otherUser.name))),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text('এখনো কোনো চ্যাট শুরু হয়নি', style: GoogleFonts.notoSansBengali(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
