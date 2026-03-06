import '../../data/models/message_model.dart';

abstract class MessageRepository {
  Future<void> sendMessage(String chatId, MessageModel message);
  Stream<List<MessageModel>> streamMessages(String chatId);
  Future<void> markMessagesAsRead(String chatId, String userId);
}
