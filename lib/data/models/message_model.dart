import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'text', 'call', 'video_call', 'image', 'video'
  final String? duration;
  final String? fileUrl; // For images or videos

  MessageModel({
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.type = 'text',
    this.duration,
    this.fileUrl,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'text',
      duration: map['duration'],
      fileUrl: map['fileUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp, // Keeping actual timestamp for immediate UI update
      'isRead': isRead,
      'type': type,
      'duration': duration,
      'fileUrl': fileUrl,
    };
  }
}
