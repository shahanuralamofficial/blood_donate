import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../../core/services/notification_service.dart';
import '../donors/donor_public_profile_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String requestId; // This is now the chatId (direct_uidA_uidB)
  final String otherUserName;
  final String? otherUserId;
  final String? requestMention; // উদাহরণ: "রোগী: রহিম (A+)"

  const ChatScreen({
    super.key,
    required this.requestId,
    required this.otherUserName,
    this.otherUserId,
    this.requestMention,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  String? _receiverId;

  @override
  void initState() {
    super.initState();
    // চ্যাট স্ক্রিনে প্রবেশের সময় এই চ্যাট আইডি সেট করা হচ্ছে যাতে নোটিফিকেশন না আসে
    NotificationService.currentChatId = widget.requestId;
    
    _receiverId = widget.otherUserId;
    if (_receiverId == null && widget.requestId.startsWith('direct_')) {
      final parts = widget.requestId.split('_');
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (parts.length >= 3 && currentUid != null) {
        _receiverId = parts[1] == currentUid ? parts[2] : parts[1];
      }
    }
  }

  @override
  void dispose() {
    // চ্যাট স্ক্রিন থেকে বের হওয়ার সময় চ্যাট আইডি ক্লিয়ার করা হচ্ছে
    NotificationService.currentChatId = null;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = ref.read(currentUserDataProvider).value;
    if (user == null) return;

    setState(() => _isSending = true);

    final message = MessageModel(
      senderId: user.uid,
      text: text,
      timestamp: DateTime.now(),
    );

    try {
      await ref.read(messageRepositoryProvider).sendMessage(widget.requestId, message);
      
      if (_receiverId != null) {
        // চ্যাট নোটিফিকেশন পাঠানো
        NotificationService().sendNotificationToUser(
          receiverId: _receiverId!,
          title: '${user.name} একটি মেসেজ পাঠিয়েছেন',
          body: text,
          data: {
            'type': 'chat',
            'chatId': widget.requestId,
            'senderName': user.name,
            'senderId': user.uid, // senderId যোগ করা হলো
          },
        );
      }

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.requestId));
    final user = ref.watch(currentUserDataProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        titleSpacing: 0,
        title: _receiverId != null 
          ? StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(_receiverId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Text(widget.otherUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
                }
                
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final otherUser = userData != null ? UserModel.fromMap(userData) : null;
                final bool isOnline = userData?['isOnline'] ?? false;

                return InkWell(
                  onTap: otherUser != null ? () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => DonorPublicProfileScreen(donor: otherUser))
                  ) : null,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: otherUser?.profileImageUrl != null ? NetworkImage(otherUser!.profileImageUrl!) : null,
                        child: otherUser?.profileImageUrl == null ? const Icon(Icons.person, size: 20) : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(otherUser?.name ?? widget.otherUserName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          Text(
                            isOnline ? 'অনলাইন' : 'অফলাইন', 
                            style: TextStyle(
                              fontSize: 10, 
                              color: isOnline ? Colors.greenAccent : Colors.white70,
                              fontWeight: FontWeight.w500
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            )
          : Text(widget.otherUserName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // রিকোয়েস্ট মেনশন কার্ড (যদি থাকে)
          if (widget.requestMention != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'প্রসঙ্গ: ${widget.requestMention}',
                      style: GoogleFonts.notoSansBengali(fontSize: 13, color: Colors.blue.shade800, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) return const Center(child: Text('কথোপকথন শুরু করুন...'));
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg, msg.senderId == user?.uid);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.red.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.text, style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 14)),
            const SizedBox(height: 2),
            Text(DateFormat('hh:mm a').format(msg.timestamp), style: TextStyle(fontSize: 9, color: isMe ? Colors.white70 : Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(hintText: 'মেসেজ লিখুন...', border: InputBorder.none),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.red,
              child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: _sendMessage),
            ),
          ],
        ),
      ),
    );
  }
}
