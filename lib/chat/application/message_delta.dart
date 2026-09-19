import '../domain/chat_message.dart';

sealed class MessageDelta {
  const MessageDelta();

  const factory MessageDelta.added(ChatMessage message) = MessageAdded;

  const factory MessageDelta.modified(ChatMessage message) = MessageModified;

  const factory MessageDelta.removed({
    required String roomId,
    String? clientId,
    String? serverId,
  }) = MessageRemoved;
}

final class MessageAdded extends MessageDelta {
  const MessageAdded(this.message);

  final ChatMessage message;
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
