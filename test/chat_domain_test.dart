import 'package:flutter_test/flutter_test.dart';
import 'package:chat_pet_mvp/chat/data/fake_chat_repository.dart';
import 'package:chat_pet_mvp/chat/domain/chat_models.dart';

void main() {
  test('fake repository exposes two rooms with interactive message kinds', () {
    final rooms = FakeChatRepository.rooms;

    expect(rooms, hasLength(2));
    expect(
      rooms.map((room) => room.id),
      containsAll(<String>['friends', 'family']),
    );
    expect(
      rooms.expand((room) => room.messages).map((message) => message.kind),
      containsAll(<MessageKind>[MessageKind.emoji, MessageKind.gif]),
    );
  });
}
