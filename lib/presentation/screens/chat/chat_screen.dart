import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/blood_request_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String requestId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.requestId,
    required this.otherUserName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

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
      // চ্যাট লিস্ট শর্টিংয়ের জন্য টাইমস্ট্যাম্প আপডেট
      await FirebaseFirestore.instance.collection('blood_requests').doc(widget.requestId).set({
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await ref.read(messageRepositoryProvider).sendMessage(widget.requestId, message);

      // নোটিফিকেশন পাঠানোর লজিক
      final request = ref.read(requestStreamByIdProvider(widget.requestId)).value;
      if (request != null) {
        final String receiverId = user.uid == request.requesterId 
            ? (request.donorId ?? '') 
            : request.requesterId;

        if (receiverId.isNotEmpty) {
          NotificationService().sendNotificationToUser(
            receiverId: receiverId,
            title: '${user.name} একটি মেসেজ পাঠিয়েছেন',
            body: text,
            data: {
              'type': 'chat',
              'requestId': widget.requestId,
              'senderName': user.name,
            },
          );
        }
      }

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('মেসেজ পাঠানো সম্ভব হয়নি: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.requestId));
    final user = ref.watch(currentUserDataProvider).value;
    final requestAsync = ref.watch(requestStreamByIdProvider(widget.requestId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: requestAsync.when(
          data: (req) {
            final bool isMeRequester = user?.uid == req.requesterId;
            final String roleLabel = isMeRequester ? '(রক্তদাতা)' : '(গ্রহীতা)';
            final String otherUserId = isMeRequester ? (req.donorId ?? '') : req.requesterId;

            final otherUserAsync = ref.watch(userStreamByIdProvider(otherUserId));
            return otherUserAsync.when(
              data: (otherUser) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${otherUser?.name ?? widget.otherUserName} $roleLabel', 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text('অনলাইন', style: TextStyle(fontSize: 10, color: Colors.greenAccent)),
                ],
              ),
              loading: () => Text(widget.otherUserName),
              error: (_, __) => Text(widget.otherUserName),
            );
          },
          loading: () => Text(widget.otherUserName),
          error: (_, __) => Text(widget.otherUserName),
        ),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('কথোপকথন শুরু করুন...'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == user?.uid;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
              error: (e, s) => Center(child: Text('এরর: $e')),
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE53935) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(msg.timestamp),
              style: TextStyle(fontSize: 9, color: isMe ? Colors.white70 : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
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
                  enabled: !_isSending,
                  decoration: const InputDecoration(hintText: 'মেসেজ লিখুন...', border: InputBorder.none),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFFE53935),
              child: _isSending 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
