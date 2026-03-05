import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/message_repository.dart';
import '../models/message_model.dart';

class MessageRepositoryImpl implements MessageRepository {
  final FirebaseFirestore _firestore;

  MessageRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> sendMessage(String chatId, MessageModel message) async {
    // chatId যদি direct_ দিয়ে শুরু হয় তবে সেটি কমন চ্যাট
    final isDirect = chatId.startsWith('direct_');
    final collectionPath = isDirect ? 'direct_chats' : 'blood_requests';
    
    // ১. মেসেজটি সাব-কালেকশনে যোগ করা
    await _firestore
        .collection(collectionPath)
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());

    // ২. যদি সরাসরি চ্যাট হয়, তবে মেইন চ্যাট ডকুমেন্টে লাস্ট মেসেজ আপডেট করা (চ্যাট লিস্টে দেখানোর জন্য)
    if (isDirect) {
      // chatId থেকে দুই ইউজারের আইডি বের করা (direct_uid1_uid2)
      final parts = chatId.split('_');
      if (parts.length >= 3) {
        await _firestore.collection('direct_chats').doc(chatId).set({
          'participants': [parts[1], parts[2]],
          'lastMessage': message.text,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  @override
  Stream<List<MessageModel>> streamMessages(String chatId) {
    final isDirect = chatId.startsWith('direct_');
    final collectionPath = isDirect ? 'direct_chats' : 'blood_requests';

    return _firestore
        .collection(collectionPath)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }
}
