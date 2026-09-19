import '../domain/chat_message.dart';

enum MessageAddedOrigin { initialSnapshot, live, localOptimistic }

sealed class MessageDelta {
  const MessageDelta();

  const factory MessageDelta.added(
    ChatMessage message, {
    MessageAddedOrigin origin,
  }) = MessageAdded;

  const factory MessageDelta.modified(ChatMessage message) = MessageModified;

  const factory MessageDelta.removed({
    required String roomId,
    String? clientId,
    String? serverId,
  }) = MessageRemoved;
}

final class MessageAdded extends MessageDelta {
  const MessageAdded(this.message, {this.origin = MessageAddedOrigin.live});

  final ChatMessage message;
  final MessageAddedOrigin origin;
}

final class MessageModified extends MessageDelta {
  const MessageModified(this.message);

  final ChatMessage message;
}

final class MessageRemoved extends MessageDelta {
  const MessageRemoved({required this.roomId, this.clientId, this.serverId});

  final String roomId;
  final String? clientId;
  final String? serverId;
}
