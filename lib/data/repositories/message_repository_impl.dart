import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/message_repository.dart';
import '../models/message_model.dart';

class MessageRepositoryImpl implements MessageRepository {
  final FirebaseFirestore _firestore;

  MessageRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> sendMessage(String requestId, MessageModel message) async {
    // requestId যদি 'direct_' দিয়ে শুরু হয় তবে সেটি সরাসরি চ্যাট কালেকশনে যাবে
    String collectionPath = requestId.startsWith('direct_') ? 'direct_chats' : 'blood_requests';
    
    await _firestore
        .collection(collectionPath)
        .doc(requestId)
        .collection('messages')
        .add(message.toMap());
  }

  @override
  Stream<List<MessageModel>> streamMessages(String requestId) {
    String collectionPath = requestId.startsWith('direct_') ? 'direct_chats' : 'blood_requests';

    return _firestore
        .collection(collectionPath)
        .doc(requestId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }
}
