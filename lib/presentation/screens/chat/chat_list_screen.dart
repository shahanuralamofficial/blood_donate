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

  // দুই ইউজারের জন্য একটি ইউনিক চ্যাট আইডি তৈরি করা
  String _getChatId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort(); // সবসময় একই অর্ডার থাকবে
    return 'direct_${ids[0]}_${ids[1]}';
  }

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
          preferredSize: const Size.fromHeight(60),
          child: _buildSearchBar(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blood_requests')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // ১. ইউজারের সাথে সম্পর্কিত সকল ইউনিক চ্যাট পার্টনার খুঁজে বের করা
          Map<String, dynamic> uniquePartners = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final requesterId = data['requesterId'];
            final donorId = data['donorId'];

            if (requesterId == currentUser.uid || donorId == currentUser.uid) {
              final otherUserId = requesterId == currentUser.uid ? donorId : requesterId;
              
              if (otherUserId != null && otherUserId.isNotEmpty && otherUserId != currentUser.uid) {
                // যদি আগে থেকেই এই ইউজারের সাথে চ্যাট লিস্টে থাকে, তবে নতুন করে যোগ করবে না (Group by User)
                if (!uniquePartners.containsKey(otherUserId)) {
                  uniquePartners[otherUserId] = {
                    'chatId': _getChatId(currentUser.uid, otherUserId),
                    'otherUserId': otherUserId,
                    'lastActivity': data['createdAt'] ?? Timestamp.now(),
                    'hospital': data['hospitalName'] ?? 'রক্তের আবেদন',
                  };
                }
              }
            }
          }

          var chatList = uniquePartners.values.toList();
          chatList.sort((a, b) => (b['lastActivity'] as Timestamp).compareTo(a['lastActivity'] as Timestamp));

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

                  return _buildChatCard(context, chat['chatId'], otherUser, chat['hospital']);
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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

  Widget _buildChatCard(BuildContext context, String chatId, UserModel otherUser, String hospital) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              requestId: chatId,
              otherUserName: otherUser.name,
            ),
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DonorPublicProfileScreen(donor: otherUser))),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.red.shade50,
            backgroundImage: otherUser.profileImageUrl != null ? NetworkImage(otherUser.profileImageUrl!) : null,
            child: otherUser.profileImageUrl == null ? const Icon(Icons.person_rounded, color: Colors.red) : null,
          ),
        ),
        title: Text(otherUser.name, style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(hospital, style: GoogleFonts.notoSansBengali(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
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
