import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../domain/repositories/message_repository.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepositoryImpl();
});

final messagesStreamProvider = StreamProvider.family<List<MessageModel>, String>((ref, requestId) {
  return ref.watch(messageRepositoryProvider).streamMessages(requestId);
});
