import 'package:freezed_annotation/freezed_annotation.dart';

import 'message_content.dart';
import 'message_draft.dart';
import 'message_status.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String clientId,
    String? serverId,
    required String roomId,
    required String senderId,
    required MessageContent content,
    @Default(MessageDeliveryStatus.pending) MessageDeliveryStatus status,
    required DateTime createdAt,
    DateTime? serverCreatedAt,
    @Default(0) double uploadProgress,
    String? error,
    @Default(false) bool isMine,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  factory ChatMessage.fromDraft(MessageDraft draft) => ChatMessage(
        clientId: draft.clientId,
        roomId: draft.roomId,
        senderId: draft.senderId,
        content: draft.content,
        createdAt: draft.createdAt,
        isMine: draft.isMine,
      );
}
