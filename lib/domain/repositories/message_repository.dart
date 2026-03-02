import '../../data/models/message_model.dart';

abstract class MessageRepository {
  Future<void> sendMessage(String requestId, MessageModel message);
  Stream<List<MessageModel>> streamMessages(String requestId);
}
