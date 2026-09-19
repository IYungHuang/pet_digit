import '../../chat/domain/chat_message.dart' as domain;
import '../../chat/domain/chat_models.dart' as legacy;
import '../../chat/domain/message_content.dart';
import 'pet_message_content_kind.dart';
import 'pet_message_target.dart';
import 'pet_world.dart';

/// Adapts every supported chat message model to one pet runtime target.
class PetMessageTargetFactory {
  const PetMessageTargetFactory._();

  static PetMessageTarget fromDomainMessage(domain.ChatMessage message) {
    final normalized = switch (message.content) {
      TextMessageContent(:final text) => _NormalizedMessage(
        contentKind: _isEmojiOnly(text)
            ? PetNormalizedContentKind.emoji
            : PetNormalizedContentKind.text,
        payload: text,
        messageText: text,
      ),
      ImageMessageContent(:final url) => _NormalizedMessage(
        contentKind: PetNormalizedContentKind.image,
        payload: url,
        messageText: url,
      ),
      VideoMessageContent(:final url, :final mimeType) => _NormalizedMessage(
        contentKind: _isGifMimeType(mimeType)
            ? PetNormalizedContentKind.gif
            : PetNormalizedContentKind.video,
        payload: url,
        messageText: url,
      ),
    };

    return _targetFor(
      id: message.serverId ?? message.clientId,
      normalized: normalized,
    );
  }

  static PetMessageTarget fromLegacyMessage(legacy.ChatMessage message) {
    final normalized = switch (message.kind) {
      legacy.MessageKind.text => _NormalizedMessage(
        contentKind: PetNormalizedContentKind.text,
        payload: message.text,
        messageText: message.text,
      ),
      legacy.MessageKind.emoji => _NormalizedMessage(
        contentKind: PetNormalizedContentKind.emoji,
        payload: message.text,
        messageText: message.text,
      ),
      legacy.MessageKind.gif => _NormalizedMessage(
        contentKind: PetNormalizedContentKind.gif,
        payload: message.text,
        messageText: message.text,
      ),
    };

    return _targetFor(id: message.id, normalized: normalized);
  }

  static PetMessageTarget _targetFor({
    required String id,
    required _NormalizedMessage normalized,
  }) => PetMessageTarget(
    id: id,
    kind: switch (normalized.contentKind) {
      PetNormalizedContentKind.text => WorldObjectKind.platform,
      PetNormalizedContentKind.emoji => WorldObjectKind.emojiToy,
      PetNormalizedContentKind.image ||
      PetNormalizedContentKind.gif ||
      PetNormalizedContentKind.video => WorldObjectKind.animatedToy,
    },
    contentKind: normalized.contentKind,
    payload: normalized.payload,
    messageText: normalized.messageText,
  );

  static bool _isGifMimeType(String mimeType) =>
      mimeType.toLowerCase() == 'image/gif';

  static bool _isEmojiOnly(String value) {
    final text = value.trim();
    return text.isNotEmpty &&
        text.runes.length <= 4 &&
        !RegExp(r'[A-Za-z0-9\u4e00-\u9fff]').hasMatch(text);
  }
}

class _NormalizedMessage {
  const _NormalizedMessage({
    required this.contentKind,
    required this.payload,
    required this.messageText,
  });

  final PetNormalizedContentKind contentKind;
  final Object? payload;
  final String messageText;
}
