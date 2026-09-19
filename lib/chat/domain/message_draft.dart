import 'package:freezed_annotation/freezed_annotation.dart';

import 'message_content.dart';

part 'message_draft.freezed.dart';

@freezed
abstract class MessageDraft with _$MessageDraft {
  const factory MessageDraft({
    required String clientId,
    required String roomId,
    required String senderId,
    required MessageContent content,
    required DateTime createdAt,
    @Default(false) bool isMine,
  }) = _MessageDraft;
}
