import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/user_model.dart';
import '../chat/chat_screen.dart';

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
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // শুধুমাত্র নতুন সিস্টেমের চ্যাটগুলো দেখাচ্ছি (যা ১০০% কাজ করবে)
              stream: FirebaseFirestore.instance
                  .collection('direct_chats')
                  .where('participants', arrayContains: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.red));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // সময়ের ভিত্তিতে সাজানো
                final List<DocumentSnapshot> chatDocs = snapshot.data!.docs.toList();
                chatDocs.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    final chatData = chatDocs[index].data() as Map<String, dynamic>;
                    final chatId = chatDocs[index].id;
                    
                    final List<dynamic> participants = chatData['participants'] ?? [];
                    final otherId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');

                    if (otherId.isEmpty) return const SizedBox.shrink();

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(otherId).get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData || userSnap.data!.data() == null) return const SizedBox.shrink();
                        final otherUser = UserModel.fromMap(userSnap.data!.data() as Map<String, dynamic>);

                        if (_searchQuery.isNotEmpty && !otherUser.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
                          return const SizedBox.shrink();
                        }

                        return _buildChatTile(
                          context, 
                          chatId, 
                          otherUser, 
                          chatData['lastMessage'] ?? 'মেসেজ পাঠানো হয়েছে', 
                          chatData['lastMessageTime'] as Timestamp?
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'নাম দিয়ে খুঁজুন...',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, String chatId, UserModel otherUser, String lastMsg, Timestamp? time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              otherUserId: otherUser.uid,
            ),
          ),
        ),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.red.shade50,
          backgroundImage: otherUser.profileImageUrl != null ? NetworkImage(otherUser.profileImageUrl!) : null,
          child: otherUser.profileImageUrl == null ? const Icon(Icons.person, color: Colors.red) : null,
        ),
        title: Text(otherUser.name, style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        trailing: time != null ? Text(_formatTime(time.toDate()), style: TextStyle(color: Colors.grey.shade400, fontSize: 11)) : null,
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (now.day == date.day && now.month == date.month && now.year == date.year) {
      return DateFormat('hh:mm a').format(date);
    }
    return DateFormat('dd/MM/yy').format(date);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text('এখনো কোনো মেসেজ নেই', style: GoogleFonts.notoSansBengali(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
