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

          // ইউজারের সাথে সম্পর্কিত সকল রিকোয়েস্ট (পেন্ডিং, এক্সেপ্টেড সব)
          var allRequests = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['requesterId'] == currentUser.uid || data['donorId'] == currentUser.uid;
          }).toList();

          Map<String, dynamic> uniqueChats = {};
          for (var doc in allRequests) {
            final data = doc.data() as Map<String, dynamic>;
            final otherUserId = data['requesterId'] == currentUser.uid ? data['donorId'] : data['requesterId'];
            
            if (otherUserId != null && otherUserId.isNotEmpty) {
              if (!uniqueChats.containsKey(otherUserId)) {
                uniqueChats[otherUserId] = {
                  'requestId': doc.id,
                  'otherUserId': otherUserId,
                  'hospitalName': data['hospitalName'] ?? 'রক্তের আবেদন',
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

  Widget _buildChatCard(BuildContext context, String requestId, UserModel otherUser, String hospital, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                requestId: requestId,
                otherUserName: otherUser.name,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DonorPublicProfileScreen(donor: otherUser))),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.red.shade50,
                    backgroundImage: otherUser.profileImageUrl != null ? NetworkImage(otherUser.profileImageUrl!) : null,
                    child: otherUser.profileImageUrl == null ? const Icon(Icons.person_rounded, color: Colors.red) : null,
                  ),
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
                            child: Text(otherUser.name, style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(hospital, style: GoogleFonts.notoSansBengali(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.blue;
    String text = 'চলমান';
    if (status == 'completed' || status == 'donated') {
      color = Colors.green;
      text = 'সফল';
    } else if (status == 'pending') {
      color = Colors.orange;
      text = 'অপেক্ষমান';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: GoogleFonts.notoSansBengali(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
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
