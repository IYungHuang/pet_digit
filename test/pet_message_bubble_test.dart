import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/chat/domain/chat_message.dart';
import 'package:chat_pet_mvp/chat/domain/message_content.dart';
import 'package:chat_pet_mvp/chat/domain/message_status.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_bubble.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world_controller.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';

void main() {
  test('wraps every domain message as an interactive pet target', () {
    final controller = PetWorldController();
    final messages = [
      _message('text', const MessageContent.text(text: 'hello')),
      _message('emoji', const MessageContent.text(text: '👋')),
      _message(
        'image',
        const MessageContent.image(url: 'photo.jpg', mimeType: 'image/jpeg'),
      ),
      _message(
        'video',
        const MessageContent.video(url: 'clip.mp4', mimeType: 'video/mp4'),
      ),
    ];

    controller.setMessageBubbleTargets(messages);

    expect(controller.objects, hasLength(4));
    expect(controller.objects.map((target) => target.id), [
      'text',
      'emoji',
      'image',
      'video',
    ]);
    controller.updateObjectBounds({
      for (final target in controller.objects)
        target.id: const Rect.fromLTWH(10, 20, 200, 60),
    });

    controller.interact('text');
    expect(controller.state, PetState.jump);
    controller.interact('emoji');
    expect(controller.state, PetState.pounce);
    controller.interact('image');
    expect(controller.state, PetState.observe);
    controller.interact('video');
    expect(controller.state, PetState.observe);
  });

  test('wrapper updates bounds used by pet interaction', () {
    final target = PetMessageBubbleTarget(
      message: _message('message', const MessageContent.text(text: 'hello')),
    );

    target.updateBounds(const Rect.fromLTWH(10, 20, 200, 60));

    expect(target.bounds, const Rect.fromLTWH(10, 20, 200, 60));
  });
}

ChatMessage _message(String id, MessageContent content) => ChatMessage(
  clientId: id,
  roomId: 'friends',
  senderId: 'sender',
  content: content,
  status: MessageDeliveryStatus.sent,
  createdAt: DateTime(2026, 9, 19),
);
