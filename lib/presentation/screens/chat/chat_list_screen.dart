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
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('লগইন প্রয়োজন')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'মেসেজ লিস্ট',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('direct_chats')
                  .where('participants', arrayContains: currentUser.uid)
                  .orderBy('lastMessageTime', descending: true) // সরাসরি ফায়ারবেস থেকে সর্ট করে আনছি
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // যদি ইনডেক্স এরর দেয় তবে আমরা ম্যানুয়ালি সর্ট করবো
                  return _buildManualSortedList(currentUser.uid);
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.red));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final chatData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final chatId = snapshot.data!.docs[index].id;
                    return _buildChatItem(chatId, chatData, currentUser.uid);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualSortedList(String currentUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('direct_chats')
          .where('participants', arrayContains: currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
          return (bTime ?? Timestamp(0, 0)).compareTo(aTime ?? Timestamp(0, 0));
        });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final chatData = docs[index].data() as Map<String, dynamic>;
            final chatId = docs[index].id;
            return _buildChatItem(chatId, chatData, currentUid);
          },
        );
      },
    );
  }

  Widget _buildChatItem(String chatId, Map<String, dynamic> chatData, String currentUid) {
    final List<dynamic> participants = chatData['participants'] ?? [];
    
    // নিজের আইডি বাদে অন্য ইউজারের আইডি বের করা
    final String otherId = participants.firstWhere(
      (id) => id.toString() != currentUid, 
      orElse: () => ''
    ).toString();

    if (otherId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(otherId).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData || !userSnap.data!.exists) return const SizedBox.shrink();
        
        final userData = userSnap.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox.shrink();
        
        final otherUser = UserModel.fromMap(userData);
        final bool isOnline = userData['isOnline'] ?? false;

        // সার্চ ফিল্টারিং
        if (_searchQuery.isNotEmpty && !otherUser.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return const SizedBox.shrink();
        }

        final String currentAuthUid = FirebaseAuth.instance.currentUser?.uid ?? '';
        final bool isUnread = (chatData['unread'] ?? false) == true && 
                             chatData['lastMessageSenderId'] != currentAuthUid;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            // হাইলাইট কালার আরও গাঢ় করা হলো (red.shade50)
            color: isUnread ? Colors.red.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? Colors.red.shade300 : Colors.grey.shade200,
              width: isUnread ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnread ? Colors.red.withOpacity(0.1) : Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    requestId: chatId,
                    otherUserName: otherUser.name,
                    otherUserId: otherUser.uid,
                  ),
                ),
              );
            },
            leading: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnread ? Colors.red : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: otherUser.profileImageUrl != null
                        ? NetworkImage(otherUser.profileImageUrl!)
                        : null,
                    child: otherUser.profileImageUrl == null
                        ? Icon(Icons.person, color: Colors.grey.shade400, size: 28)
                        : null,
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              otherUser.name,
              style: GoogleFonts.notoSansBengali(
                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                fontSize: 16,
                color: isUnread ? Colors.red.shade900 : Colors.black87,
              ),
            ),
            subtitle: Text(
              chatData['lastMessage'] ?? 'মেসেজ শুরু করুন',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUnread ? Colors.black : Colors.grey.shade600,
                fontSize: 13,
                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (chatData['lastMessageTime'] != null)
                  Text(
                    _formatTime((chatData['lastMessageTime'] as Timestamp).toDate()),
                    style: TextStyle(
                      color: isUnread ? Colors.red.shade700 : Colors.grey.shade500, 
                      fontSize: 11,
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                const SizedBox(height: 8),
                if (isUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'নাম দিয়ে খুঁজুন...',
          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('hh:mm a').format(date);
    } else if (difference.inDays == 1) {
      return 'গতকাল';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date); // সপ্তাহের নাম
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
            child: Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.red.shade200),
          ),
          const SizedBox(height: 16),
          Text(
            'এখনো কোনো মেসেজ নেই',
            style: GoogleFonts.notoSansBengali(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
