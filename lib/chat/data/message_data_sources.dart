import '../domain/chat_message.dart';
import '../domain/message_content.dart';
import '../domain/message_draft.dart';

class RemoteMessageReceipt {
  const RemoteMessageReceipt({
    required this.serverId,
    required this.serverCreatedAt,
  });

  final String serverId;
  final DateTime serverCreatedAt;
}

abstract interface class MessageRemoteDataSource {
  Future<RemoteMessageReceipt> send(MessageDraft draft);
}

abstract interface class MediaUploadDataSource {
  Future<MessageContent> upload(
    MessageDraft draft, {
    void Function(double progress)? onProgress,
  });
}

abstract interface class MessageEventSource {
  Stream<ChatMessage> events();

  Future<void> connect();

  Future<void> disconnect();
}
