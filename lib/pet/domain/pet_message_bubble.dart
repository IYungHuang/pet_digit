import 'dart:ui';

import '../../chat/domain/chat_message.dart';
import '../../chat/domain/message_content.dart';
import 'pet_world.dart';

class PetMessageBubbleTarget implements PetBoundedInteractable {
  PetMessageBubbleTarget({required this.message, Rect? bounds})
    : bounds = bounds ?? const Rect.fromLTWH(0, 0, 180, 52);

  final ChatMessage message;
  @override
  Rect bounds;

  @override
  String get id => message.clientId;

  @override
  Offset get position => bounds.topLeft;

  @override
  WorldObjectKind get kind => switch (message.content) {
    TextMessageContent(:final text) when _isEmojiOnly(text) =>
      WorldObjectKind.emojiToy,
    TextMessageContent() => WorldObjectKind.platform,
    ImageMessageContent() ||
    VideoMessageContent() => WorldObjectKind.animatedToy,
  };

  @override
  PetState interactionFor(PetEvent event) => switch (kind) {
    WorldObjectKind.platform => PetState.jump,
    WorldObjectKind.emojiToy => PetState.pounce,
    WorldObjectKind.animatedToy => PetState.observe,
  };

  @override
  void updateBounds(Rect newBounds) {
    bounds = newBounds;
  }

  static bool _isEmojiOnly(String value) {
    final text = value.trim();
    return text.isNotEmpty &&
        text.runes.length <= 4 &&
        !RegExp(r'[A-Za-z0-9\u4e00-\u9fff]').hasMatch(text);
  }
}
