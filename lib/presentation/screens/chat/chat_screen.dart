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
import 'voice_call_screen.dart';
import '../../providers/language_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String requestId;
  final String otherUserName;
  final String? otherUserId;
  final String? requestMention;

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
    if (NotificationService.currentChatId != null) {
      NotificationService.clearNotifiedChat(NotificationService.currentChatId!);
    }
    NotificationService.currentChatId = null;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleMenuAction(String value) async {
    final user = ref.read(currentUserDataProvider).value;
    if (user == null || _receiverId == null) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    if (value == 'block') {
      final isBlocked = user.blockedUsers.contains(_receiverId);
      await userRef.update({
        'blockedUsers': isBlocked ? FieldValue.arrayRemove([_receiverId]) : FieldValue.arrayUnion([_receiverId])
      });
    } else if (value == 'block_call') {
      final isCallBlocked = user.callBlockedUsers.contains(_receiverId);
      await userRef.update({
        'callBlockedUsers': isCallBlocked ? FieldValue.arrayRemove([_receiverId]) : FieldValue.arrayUnion([_receiverId])
      });
    } else if (value == 'mute') {
      final isMuted = user.mutedChats.contains(widget.requestId);
      await userRef.update({
        'mutedChats': isMuted ? FieldValue.arrayRemove([widget.requestId]) : FieldValue.arrayUnion([widget.requestId])
      });
    }
  }

  void _initiateCall(BuildContext context, {required bool isVideo}) async {
    final user = ref.read(currentUserDataProvider).value;
    if (user == null || _receiverId == null) return;

    // ১. আমি তাকে ব্লক করেছি কি না চেক
    if (user.blockedUsers.contains(_receiverId)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.tr('unblock_to_call'))));
      return;
    }

    // ২. আমি তাকে কল ব্লক করেছি কি না চেক
    if (user.callBlockedUsers.contains(_receiverId)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.tr('unblock_call_to_call'))));
      return;
    }

    // ৩. সে আমাকে ব্লক বা কল ব্লক করেছে কি না চেক
    final receiverDoc = await FirebaseFirestore.instance.collection('users').doc(_receiverId).get();
    final receiverData = receiverDoc.data();
    if (receiverData != null) {
      final List<dynamic> receiverBlockedList = receiverData['blockedUsers'] ?? [];
      final List<dynamic> receiverCallBlockedList = receiverData['callBlockedUsers'] ?? [];
      
      if (receiverBlockedList.contains(user.uid) || receiverCallBlockedList.contains(user.uid)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.tr('cannot_call_this_user'))));
        return;
      }
    }

    await NotificationService().sendNotificationToUser(
      receiverId: _receiverId!,
      title: isVideo ? 'রক্তদান - ভিডিও কল' : 'রক্তদান - ভয়েস কল',
      body: '${user.name} আপনাকে ${isVideo ? 'ভিডিও' : 'ভয়েস'} কল দিচ্ছে...',
      data: {
        'type': 'call',
        'channelId': widget.requestId,
        'senderName': user.name,
        'isVideo': isVideo.toString(),
      },
    );

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(
        channelId: widget.requestId, otherUserName: widget.otherUserName, isVideoCall: isVideo,
      )));
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    final user = ref.read(currentUserDataProvider).value;
    if (user == null) return;

    setState(() => _isSending = true);
    final message = MessageModel(senderId: user.uid, text: text, timestamp: DateTime.now());

    try {
      await ref.read(messageRepositoryProvider).sendMessage(widget.requestId, message);
      if (_receiverId != null) {
        await NotificationService().sendNotificationToUser(
          receiverId: _receiverId!,
          title: '${user.name} ${ref.tr('message_sent_notification')}',
          body: text,
          data: {'type': 'chat', 'chatId': widget.requestId, 'senderName': user.name, 'senderId': user.uid},
        );
      }
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    final user = ref.watch(currentUserDataProvider).value;
    if (user != null) {
      ref.read(messageRepositoryProvider).markMessagesAsRead(widget.requestId, user.uid);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        titleSpacing: 0,
        title: _buildAppBarTitle(),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_receiverId != null) ...[
            IconButton(icon: const Icon(Icons.call), onPressed: () => _initiateCall(context, isVideo: false)),
            IconButton(icon: const Icon(Icons.videocam), onPressed: () => _initiateCall(context, isVideo: true)),
            _buildPopupMenu(user),
          ]
        ],
      ),
      body: _buildChatBody(user),
    );
  }

  Widget _buildAppBarTitle() {
    if (_receiverId == null) return Text(widget.otherUserName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_receiverId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return Text(widget.otherUserName);
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final otherUser = userData != null ? UserModel.fromMap(userData) : null;
        final bool isOnline = userData?['isOnline'] ?? false;
        return InkWell(
          onTap: otherUser != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => DonorPublicProfileScreen(donor: otherUser))) : null,
          child: Row(children: [
            CircleAvatar(radius: 18, backgroundImage: otherUser?.profileImageUrl != null ? NetworkImage(otherUser!.profileImageUrl!) : null, child: otherUser?.profileImageUrl == null ? const Icon(Icons.person, size: 20) : null),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(otherUser?.name ?? widget.otherUserName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text(isOnline ? ref.tr('online') : ref.tr('offline'), style: TextStyle(fontSize: 10, color: isOnline ? Colors.greenAccent : Colors.white70)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildPopupMenu(UserModel? user) {
    final isBlocked = user?.blockedUsers.contains(_receiverId) ?? false;
    final isCallBlocked = user?.callBlockedUsers.contains(_receiverId) ?? false;
    final isMuted = user?.mutedChats.contains(widget.requestId) ?? false;
    
    return PopupMenuButton<String>(
      onSelected: _handleMenuAction,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      itemBuilder: (context) => [
        _buildPopupItem(
          value: 'mute',
          icon: isMuted ? Icons.notifications_active : Icons.notifications_off,
          text: isMuted ? ref.tr('unmute_chat') : ref.tr('mute_chat'),
          iconColor: isMuted ? Colors.green : Colors.grey,
        ),
        _buildPopupItem(
          value: 'block_call',
          icon: isCallBlocked ? Icons.phone_callback : Icons.phone_disabled,
          text: isCallBlocked ? ref.tr('unblock_call') : ref.tr('block_call'),
          iconColor: isCallBlocked ? Colors.green : Colors.orange,
        ),
        _buildPopupItem(
          value: 'block',
          icon: Icons.block,
          text: isBlocked ? ref.tr('unblock_user') : ref.tr('block_user'),
          iconColor: isBlocked ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem({
    required String value,
    required IconData icon,
    required String text,
    required Color iconColor,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.notoSansBengali(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBody(UserModel? currentUser) {
    if (currentUser?.blockedUsers.contains(_receiverId) ?? false) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.block, size: 60, color: Colors.grey),
        const SizedBox(height: 16),
        Text(ref.tr('you_blocked_this_user'), style: const TextStyle(color: Colors.grey)),
        TextButton(onPressed: () => _handleMenuAction('block'), child: Text(ref.tr('unblock_now'))),
      ]));
    }
    
    final messagesAsync = ref.watch(messagesStreamProvider(widget.requestId));
    return Column(children: [
      if (widget.requestMention != null) _buildRequestMention(),
      Expanded(child: messagesAsync.when(
        data: (messages) => ListView.builder(controller: _scrollController, reverse: true, padding: const EdgeInsets.all(16), itemCount: messages.length, itemBuilder: (context, index) => _buildMessageBubble(messages[index], messages[index].senderId == currentUser?.uid)),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
        error: (e, s) => Center(child: Text('Error: $e')),
      )),
      _buildInputArea(),
    ]);
  }

  Widget _buildRequestMention() {
    return Container(width: double.infinity, margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)), child: Row(children: [
      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text('${ref.tr('context')}: ${widget.requestMention}', style: GoogleFonts.notoSansBengali(fontSize: 13, color: Colors.blue.shade800, fontWeight: FontWeight.w500))),
    ]));
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    return Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
      Container(margin: const EdgeInsets.only(bottom: 2), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), decoration: BoxDecoration(color: isMe ? Colors.red.shade600 : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)]), child: Text(msg.text, style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 14))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(DateFormat('hh:mm a', ref.watch(languageProvider).languageCode).format(msg.timestamp), style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
        if (isMe) ...[const SizedBox(width: 4), Icon(msg.isRead ? Icons.done_all : Icons.done, size: 12, color: msg.isRead ? Colors.blue : Colors.grey)],
      ])),
      const SizedBox(height: 6),
    ]));
  }

  Widget _buildInputArea() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -2))]), child: SafeArea(child: Row(children: [
      Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(24)), child: TextField(controller: _messageController, decoration: InputDecoration(hintText: ref.tr('type_message'), border: InputBorder.none), onSubmitted: (_) => _sendMessage()))),
      const SizedBox(width: 8),
      CircleAvatar(backgroundColor: Colors.red, child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: _sendMessage)),
    ])));
  }
}
