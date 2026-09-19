import '../domain/chat_message.dart';
import '../domain/message_content.dart';
import '../domain/message_draft.dart';
import '../domain/message_connection_state.dart';

class RemoteMessageReceipt {
  const RemoteMessageReceipt({
    required this.serverId,
    required this.serverCreatedAt,
  });

  final String serverId;
  final DateTime serverCreatedAt;
}

abstract interface class MessageRemoteDataSource {
  Future<RemoteMessageReceipt> send(
    MessageDraft draft, {
    void Function(double progress)? onProgress,
  });
}

abstract interface class MediaUploadDataSource {
  /// True when [MessageRemoteDataSource.send] uploads media atomically.
  bool get isAtomicUpload => false;

  Future<MessageContent> upload(
    MessageDraft draft, {
    void Function(double progress)? onProgress,
  });
}

abstract interface class MessageEventSource {
  Stream<ChatMessage> events();

  Stream<MessageConnectionState> connectionStates();

  Future<void> connect();

  Future<void> disconnect();
}
