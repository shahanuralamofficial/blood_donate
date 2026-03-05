import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String requestId; // এটি এখন সরাসরি চ্যাট আইডি অথবা অন্য ইউজারের আইডি হতে পারে
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

  @override
  void initState() {
    super.initState();
    _calculateChatId();
  }

  void _calculateChatId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // যদি অলরেডি direct_ আইডি থাকে তবে সেটিই ব্যবহার করো
    if (widget.requestId.startsWith('direct_')) {
      _finalChatId = widget.requestId;
    } else if (widget.otherUserId != null) {
      // অন্য ইউজারের আইডি থাকলে ইউনিক আইডি তৈরি করো
      List<String> ids = [currentUser.uid, widget.otherUserId!];
      ids.sort();
      _finalChatId = 'direct_${ids[0]}_${ids[1]}';
    } else {
      // ব্যাকওয়ার্ড কম্প্যাটিবিলিটির জন্য
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
                    final isMe = msg.senderId == user?.uid;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
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
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE53935) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(msg.text, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: 'মেসেজ লিখুন...', border: InputBorder.none),
            ),
          ),
          IconButton(icon: const Icon(Icons.send, color: Colors.red), onPressed: _sendMessage),
        ],
      ),
    );
  }
}
