import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'text', 'call', 'video_call'
  final String? duration;

  MessageModel({
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.type = 'text',
    this.duration,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'text',
      duration: map['duration'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'type': type,
      'duration': duration,
    };
  }
}
