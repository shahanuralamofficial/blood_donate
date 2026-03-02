import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text('মেসেজ লিস্ট', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('blood_requests')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // ১. ইউজার যে রিকোয়েস্টগুলোর সাথে জড়িত সেগুলো ফিল্টার করা
                var chatRequests = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isRelated = data['requesterId'] == currentUser.uid || data['donorId'] == currentUser.uid;
                  // চ্যাটগুলো তখনই দেখাবে যখন দাতা রাজি হবে
                  final isAccepted = ['accepted', 'donated', 'completed'].contains(data['status']);
                  return isRelated && isAccepted;
                }).toList();

                // ২. সর্বশেষ মেসেজ অনুযায়ী সর্টিং
                chatRequests.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final timeA = dataA['lastMessageTime'] ?? dataA['createdAt'] ?? Timestamp.now();
                  final timeB = dataB['lastMessageTime'] ?? dataB['createdAt'] ?? Timestamp.now();
                  return (timeB as Timestamp).compareTo(timeA as Timestamp);
                });

                if (chatRequests.isEmpty) {
                  return const Center(child: Text('কোন চ্যাট পাওয়া যায়নি'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: chatRequests.length,
                  itemBuilder: (context, index) {
                    final req = chatRequests[index];
                    final data = req.data() as Map<String, dynamic>;
                    final isRequester = data['requesterId'] == currentUser.uid;
                    final roleLabel = isRequester ? '(রক্তদাতা)' : '(গ্রহীতা)';
                    
                    final hospitalName = (data['hospitalName'] ?? '').toString().toLowerCase();
                    final patientName = (data['patientName'] ?? '').toString().toLowerCase();

                    if (_searchQuery.isNotEmpty && 
                        !hospitalName.contains(_searchQuery.toLowerCase()) && 
                        !patientName.contains(_searchQuery.toLowerCase())) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade50,
                          child: Text(data['bloodGroup'] ?? '?', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                        title: Text('${data['patientName'] ?? 'নাম নেই'} $roleLabel', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['hospitalName'] ?? '', style: const TextStyle(fontSize: 13)),
                            Text('${data['thana'] ?? ''}, ${data['district'] ?? ''}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(requestId: req.id, otherUserName: isRequester ? 'রক্তদাতা' : 'গ্রহীতা'))),
                      ),
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
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFE53935),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'চ্যাট খুঁজুন...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }
}
