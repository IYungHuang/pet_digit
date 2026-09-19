import 'chat_message.dart';
import 'message_draft.dart';
import '../application/message_delta.dart';

abstract interface class MessageRepository {
  Future<void> dispose();

  Future<void> connect();

  Future<void> disconnect();

  Future<void> reconnect();

  Future<List<ChatMessage>> loadMessages(String roomId);

  Stream<List<ChatMessage>> watchRoomMessages(String roomId);

  Stream<MessageDelta> watchDeltas();

  Stream<ChatMessage> watchIncomingMessages();

  Future<ChatMessage> send(
    MessageDraft draft, {
    void Function(double progress)? onUploadProgress,
  });
}
