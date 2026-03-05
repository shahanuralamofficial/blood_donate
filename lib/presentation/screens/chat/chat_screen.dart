import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String requestId;
  final String otherUserName;
  final String? otherUserId;

  const ChatScreen({
    super.key,
    required this.requestId,
    required this.otherUserName,
    this.otherUserId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  late String _finalChatId;
  String? _receiverId;

  @override
  void initState() {
    super.initState();
    _calculateChatId();
    _receiverId = widget.otherUserId;
  }

  void _calculateChatId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (widget.requestId.startsWith('direct_')) {
      _finalChatId = widget.requestId;
      // আইডি থেকে রিসিভার আইডি বের করা যদি widget.otherUserId নাল হয়
      if (_receiverId == null) {
        final parts = widget.requestId.split('_');
        if (parts.length >= 3) {
          _receiverId = parts[1] == currentUser.uid ? parts[2] : parts[1];
        }
      }
    } else if (widget.otherUserId != null) {
      List<String> ids = [currentUser.uid, widget.otherUserId!];
      ids.sort();
      _finalChatId = 'direct_${ids[0]}_${ids[1]}';
    } else {
      _finalChatId = widget.requestId;
    }
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
      await ref.read(messageRepositoryProvider).sendMessage(_finalChatId, message);
      
      // নোটিফিকেশন পাঠানোর লজিক
      if (_receiverId != null && _receiverId!.isNotEmpty) {
        NotificationService().sendNotificationToUser(
          receiverId: _receiverId!,
          title: '${user.name} একটি মেসেজ পাঠিয়েছেন',
          body: text,
          data: {
            'type': 'chat',
            'chatId': _finalChatId,
            'senderName': user.name,
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
    final messagesAsync = ref.watch(messagesStreamProvider(_finalChatId));
    final user = ref.watch(currentUserDataProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(widget.otherUserName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) return const Center(child: Text('মেসেজ পাঠিয়ে চ্যাট শুরু করুন...'));
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
          color: isMe ? const Color(0xFFE53935) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)],
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
      color: Colors.white,
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
            IconButton(icon: const Icon(Icons.send_rounded, color: Colors.red), onPressed: _sendMessage),
          ],
        ),
      ),
    );
  }
}
