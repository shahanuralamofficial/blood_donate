import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/message_repository.dart';
import '../models/message_model.dart';

class MessageRepositoryImpl implements MessageRepository {
  final FirebaseFirestore _firestore;

  MessageRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> sendMessage(String chatId, MessageModel message) async {
    // এখানে আমরা কঠোরভাবে চ্যাট আইডি ফরম্যাট চেক করব।
    // চ্যাট আইডি অবশ্যই 'direct_uid1_uid2' ফরম্যাটে হতে হবে।
    if (!chatId.startsWith('direct_')) {
      throw Exception('Invalid Chat Protocol. Only direct user-to-user chats are allowed.');
    }

    final parts = chatId.split('_');
    if (parts.length < 3) throw Exception('Invalid Chat ID format.');

    final participants = [parts[1], parts[2]];

    // ১. মেইন চ্যাট ডকুমেন্টে মেটাডাটা সেভ করা (participants মাস্ট)
    await _firestore.collection('direct_chats').doc(chatId).set({
      'participants': participants,
      'lastMessage': message.text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ২. মেসেজটি 'messages' সাব-কালেকশনে যোগ করা
    await _firestore
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());
  }

  @override
  Stream<List<MessageModel>> streamMessages(String chatId) {
    // শুধুমাত্র direct_chats থেকে ডাটা স্ট্রিম হবে
    return _firestore
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }
}
