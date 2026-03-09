import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../data/models/user_model.dart';
import '../../../data/models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/cloudinary_service.dart';
import '../donors/donor_public_profile_screen.dart';
import 'voice_call_screen.dart';
import 'video_player_widget.dart';
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
  File? _selectedMedia;
  bool _isMediaVideo = false;
  final _captionController = TextEditingController();

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
    _captionController.dispose();
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

    if (user.blockedUsers.contains(_receiverId)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.tr('unblock_to_call'))));
      return;
    }

    if (user.callBlockedUsers.contains(_receiverId)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.tr('unblock_call_to_call'))));
      return;
    }

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

  void _pickMedia({required bool isVideo}) async {
    final picker = ImagePicker();
    final XFile? file = isVideo 
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (file == null) return;

    setState(() {
      _selectedMedia = File(file.path);
      _isMediaVideo = isVideo;
      _captionController.clear();
    });
  }

  void _sendMediaMessage() async {
    if (_selectedMedia == null || _isSending) return;
    
    final user = ref.read(currentUserDataProvider).value;
    if (user == null) return;

    final mediaFile = _selectedMedia!;
    final isVideo = _isMediaVideo;
    final caption = _captionController.text.trim();

    setState(() {
      _isSending = true;
      _selectedMedia = null; // Clear preview immediately
    });

    try {
      final String? downloadUrl = await CloudinaryService.uploadFile(mediaFile, isVideo: isVideo);
      
      if (downloadUrl != null) {
        final message = MessageModel(
          senderId: user.uid,
          text: caption.isNotEmpty ? caption : (isVideo ? "ভিডিও ফাইল" : "ছবি"),
          timestamp: DateTime.now(),
          type: isVideo ? 'video' : 'image',
          fileUrl: downloadUrl,
        );

        await ref.read(messageRepositoryProvider).sendMessage(widget.requestId, message);
        
        if (_receiverId != null) {
          await NotificationService().sendNotificationToUser(
            receiverId: _receiverId!,
            title: user.name,
            body: isVideo ? 'আপনাকে একটি ভিডিও পাঠিয়েছেন' : 'আপনাকে একটি ছবি পাঠিয়েছেন',
            data: {'type': 'chat', 'chatId': widget.requestId},
          );
        }
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
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
            IconButton(icon: const Icon(Icons.call, size: 22), onPressed: () => _initiateCall(context, isVideo: false)),
            IconButton(icon: const Icon(Icons.videocam, size: 22), onPressed: () => _initiateCall(context, isVideo: true)),
            _buildPopupMenu(user),
          ]
        ],
      ),
      body: _buildChatBody(user),
    );
  }

  Widget _buildAppBarTitle() {
    if (_receiverId == null) return Text(widget.otherUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis);
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_receiverId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return Text(widget.otherUserName, overflow: TextOverflow.ellipsis);
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final otherUser = userData != null ? UserModel.fromMap(userData) : null;
        final bool isOnline = userData?['isOnline'] ?? false;
        return InkWell(
          onTap: otherUser != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => DonorPublicProfileScreen(donor: otherUser))) : null,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(radius: 18, backgroundImage: otherUser?.profileImageUrl != null ? NetworkImage(otherUser!.profileImageUrl!) : null, child: otherUser?.profileImageUrl == null ? const Icon(Icons.person, size: 20) : null),
            const SizedBox(width: 8),
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(otherUser?.name ?? widget.otherUserName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text(isOnline ? ref.tr('online') : ref.tr('offline'), style: TextStyle(fontSize: 10, color: isOnline ? Colors.greenAccent : Colors.white70)),
              ]),
            ),
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
        _buildPopupItem(value: 'mute', icon: isMuted ? Icons.notifications_active : Icons.notifications_off, text: isMuted ? ref.tr('unmute_chat') : ref.tr('mute_chat'), iconColor: isMuted ? Colors.green : Colors.grey),
        _buildPopupItem(value: 'block_call', icon: isCallBlocked ? Icons.phone_callback : Icons.phone_disabled, text: isCallBlocked ? ref.tr('unblock_call') : ref.tr('block_call'), iconColor: isCallBlocked ? Colors.green : Colors.orange),
        _buildPopupItem(value: 'block', icon: Icons.block, text: isBlocked ? ref.tr('unblock_user') : ref.tr('block_user'), iconColor: isBlocked ? Colors.green : Colors.red),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem({required String value, required IconData icon, required String text, required Color iconColor}) {
    return PopupMenuItem(value: value, child: Row(children: [Icon(icon, color: iconColor, size: 20), const SizedBox(width: 12), Text(text, style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87))]));
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
    return Stack(
      children: [
        Column(children: [
          if (widget.requestMention != null) _buildRequestMention(),
          Expanded(child: messagesAsync.when(
            data: (messages) => ListView.builder(controller: _scrollController, reverse: true, padding: const EdgeInsets.all(16), itemCount: messages.length, itemBuilder: (context, index) => _buildMessageBubble(messages[index], messages[index].senderId == currentUser?.uid)),
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
            error: (e, s) => Center(child: Text('Error: $e')),
          )),
          _buildInputArea(),
        ]),
        if (_selectedMedia != null) _buildMediaPreview(),
      ],
    );
  }

  Widget _buildMediaPreview() {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _selectedMedia = null),
                ),
                title: Text(_isMediaVideo ? "ভিডিও প্রিভিউ" : "ছবি প্রিভিউ", style: const TextStyle(color: Colors.white)),
              ),
              Expanded(
                child: Center(
                  child: _isMediaVideo 
                    ? const Icon(Icons.play_circle_fill, size: 80, color: Colors.white)
                    : Image.file(_selectedMedia!, fit: BoxFit.contain),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black54,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _captionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "ক্যাপশন লিখুন...",
                          hintStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.white10,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMediaMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestMention() {
    return Container(width: double.infinity, margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)), child: Row(children: [
      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text('${ref.tr('context')}: ${widget.requestMention}', style: GoogleFonts.notoSansBengali(fontSize: 13, color: Colors.blue.shade800, fontWeight: FontWeight.w500))),
    ]));
  }

  Widget _buildCallLogBubble(MessageModel msg) {
    final bool isMissed = msg.text.contains("মিসড") || msg.text.contains("Missed");
    final bool isVideo = msg.type == 'video_call';

    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isMissed ? Colors.red.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isMissed ? Colors.red.shade100 : Colors.blue.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMissed 
                  ? Icons.call_missed 
                  : (isVideo ? Icons.videocam : Icons.call),
              size: 16,
              color: isMissed ? Colors.red : Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(
              msg.text,
              style: GoogleFonts.notoSansBengali(
                fontSize: 12,
                color: isMissed ? Colors.red.shade700 : Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (msg.duration != null && msg.duration!.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                "(${msg.duration})",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    if (msg.type == 'call' || msg.type == 'video_call') {
      return _buildCallLogBubble(msg);
    }

    return Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
      Container(
        margin: const EdgeInsets.only(bottom: 2), 
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), 
        decoration: BoxDecoration(color: isMe ? Colors.red.shade600 : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)]), 
      child: msg.type == 'image' 
          ? _buildImageContent(msg.fileUrl!, isMe, msg.text)
          : msg.type == 'video'
            ? _buildVideoContent(msg.fileUrl!, isMe, msg.text)
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? Colors.red.shade600 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(msg.text, style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 14))
              )
      ),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(DateFormat('hh:mm a', ref.watch(languageProvider).languageCode).format(msg.timestamp), style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
        if (isMe) ...[const SizedBox(width: 4), Icon(msg.isRead ? Icons.done_all : Icons.done, size: 12, color: msg.isRead ? Colors.blue : Colors.grey)],
      ])),
      const SizedBox(height: 6),
    ]));
  }

  Widget _buildImageContent(String url, bool isMe, String caption) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              // Full screen logic can be added here
            },
            child: CachedNetworkImage(
              imageUrl: url,
              placeholder: (context, url) => Container(
                width: 200,
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (caption.isNotEmpty && caption != "ছবি")
          Container(
            width: 200,
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? Colors.red.shade600 : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              caption,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoContent(String url, bool isMe, String caption) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerWidget(videoUrl: url))),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 150,
            color: Colors.black,
            child: const Icon(Icons.video_collection, color: Colors.white, size: 40),
          ),
          const CircleAvatar(
            backgroundColor: Colors.white54,
            child: Icon(Icons.play_arrow, color: Colors.black),
          ),
          if (caption.isNotEmpty && caption != "ভিডিও ফাইল")
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black45,
                child: Text(caption, style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -2))]), child: SafeArea(child: Row(children: [
      IconButton(
        icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.image),
                    title: const Text('ছবি পাঠান'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickMedia(isVideo: false);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.videocam),
                    title: const Text('ভিডিও পাঠান'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickMedia(isVideo: true);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(24)), child: TextField(controller: _messageController, decoration: InputDecoration(hintText: ref.tr('type_message'), border: InputBorder.none), onSubmitted: (_) => _sendMessage()))),
      const SizedBox(width: 8),
      _isSending
          ? const SizedBox(width: 40, height: 40, child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
          : CircleAvatar(backgroundColor: Colors.red, child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: _sendMessage)),
    ])));
  }
}
