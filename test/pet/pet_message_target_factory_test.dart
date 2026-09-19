import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/chat/domain/chat_message.dart' as domain;
import 'package:chat_pet_mvp/chat/domain/chat_models.dart' as legacy;
import 'package:chat_pet_mvp/chat/domain/message_content.dart';
import 'package:chat_pet_mvp/chat/domain/message_status.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_content_kind.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_target_factory.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';

void main() {
  test('domain message uses server id as canonical target id', () {
    final target = PetMessageTargetFactory.fromDomainMessage(
      _domainMessage(
        clientId: 'client-1',
        serverId: 'server-1',
        content: const MessageContent.text(text: 'hello'),
      ),
    );

    expect(target.id, 'server-1');
    expect(target.kind, WorldObjectKind.platform);
    expect(target.contentKind, PetNormalizedContentKind.text);
    expect(target.payload, 'hello');
    expect(target.messageText, 'hello');
    expect(target.hasMeasuredBounds, isFalse);
  });

  test(
    'domain message falls back to client id before server acknowledgement',
    () {
      final target = PetMessageTargetFactory.fromDomainMessage(
        _domainMessage(
          clientId: 'client-1',
          content: const MessageContent.text(text: 'hello'),
        ),
      );

      expect(target.id, 'client-1');
    },
  );

  test('domain emoji and media normalize to distinct content kinds', () {
    final emojiTarget = PetMessageTargetFactory.fromDomainMessage(
      _domainMessage(
        clientId: 'emoji',
        content: const MessageContent.text(text: '👋'),
      ),
    );
    final imageTarget = PetMessageTargetFactory.fromDomainMessage(
      _domainMessage(
        clientId: 'image',
        content: const MessageContent.image(
          url: 'photo.jpg',
          mimeType: 'image/jpeg',
        ),
      ),
    );
    final gifTarget = PetMessageTargetFactory.fromDomainMessage(
      _domainMessage(
        clientId: 'gif',
        content: const MessageContent.video(
          url: 'dance.gif',
          mimeType: 'image/gif',
        ),
      ),
    );
    final videoTarget = PetMessageTargetFactory.fromDomainMessage(
      _domainMessage(
        clientId: 'video',
        content: const MessageContent.video(
          url: 'clip.mp4',
          mimeType: 'video/mp4',
        ),
      ),
    );

    expect(emojiTarget.contentKind, PetNormalizedContentKind.emoji);
    expect(emojiTarget.kind, WorldObjectKind.emojiToy);
    expect(emojiTarget.payload, '👋');
    expect(imageTarget.contentKind, PetNormalizedContentKind.image);
    expect(imageTarget.kind, WorldObjectKind.animatedToy);
    expect(imageTarget.payload, 'photo.jpg');
    expect(gifTarget.contentKind, PetNormalizedContentKind.gif);
    expect(gifTarget.kind, WorldObjectKind.animatedToy);
    expect(gifTarget.payload, 'dance.gif');
    expect(videoTarget.contentKind, PetNormalizedContentKind.video);
    expect(videoTarget.kind, WorldObjectKind.animatedToy);
    expect(videoTarget.payload, 'clip.mp4');
  });

  test('legacy message uses stable id and normalized payload', () {
    final target = PetMessageTargetFactory.fromLegacyMessage(
      const legacy.ChatMessage(
        id: 'legacy-gif',
        sender: 'Mina',
        text: 'corgi-dance.gif',
        kind: legacy.MessageKind.gif,
        isMine: false,
      ),
    );

    expect(target.id, 'legacy-gif');
    expect(target.kind, WorldObjectKind.animatedToy);
    expect(target.contentKind, PetNormalizedContentKind.gif);
    expect(target.payload, 'corgi-dance.gif');
    expect(target.messageText, 'corgi-dance.gif');
  });

  test('measured bounds become ready only after explicit measurement', () {
    final target = PetMessageTargetFactory.fromLegacyMessage(
      const legacy.ChatMessage(
        id: 'legacy-emoji',
        sender: 'Mina',
        text: '🐕',
        kind: legacy.MessageKind.emoji,
        isMine: false,
      ),
    );
    const bounds = Rect.fromLTWH(10, 20, 200, 60);

    expect(target.hasMeasuredBounds, isFalse);

    target.markMeasuredBounds(bounds);

    expect(target.hasMeasuredBounds, isTrue);
    expect(target.bounds, bounds);
  });
}

domain.ChatMessage _domainMessage({
  required String clientId,
  String? serverId,
  required MessageContent content,
}) => domain.ChatMessage(
  clientId: clientId,
  serverId: serverId,
  roomId: 'room-1',
  senderId: 'sender-1',
  content: content,
  status: MessageDeliveryStatus.sent,
  createdAt: DateTime(2026, 9, 19),
);
