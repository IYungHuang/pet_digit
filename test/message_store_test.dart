import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/chat/application/message_delta.dart';
import 'package:chat_pet_mvp/chat/application/message_store.dart';
import 'package:chat_pet_mvp/chat/domain/chat_message.dart';
import 'package:chat_pet_mvp/chat/domain/message_content.dart';
import 'package:chat_pet_mvp/chat/domain/message_status.dart';

void main() {
  test('merges added messages in createdAt order', () {
    final store = MessageStore();
    final later = _message('later', DateTime(2026, 9, 19, 8, 2));
    final earlier = _message('earlier', DateTime(2026, 9, 19, 8, 1));

    store.apply(MessageDelta.added(later));
    store.apply(MessageDelta.added(earlier));

    expect(
      store.messagesForRoom('friends').map((message) => message.clientId),
      ['earlier', 'later'],
    );
  });

  test('modifies existing message without changing collection cardinality', () {
    final store = MessageStore();
    store.apply(MessageDelta.added(_message('m1', DateTime(2026, 9, 19))));

    store.apply(
      MessageDelta.modified(
        _message(
          'm1',
          DateTime(2026, 9, 19),
        ).copyWith(content: const MessageContent.text(text: 'edited')),
      ),
    );

    final messages = store.messagesForRoom('friends');
    expect(messages, hasLength(1));
    expect(messages.single.content, const MessageContent.text(text: 'edited'));
  });

  test('merges canonical echo into optimistic client message', () {
    final store = MessageStore();
    store.apply(
      MessageDelta.added(
        _message(
          'local-1',
          DateTime(2026, 9, 19),
        ).copyWith(status: MessageDeliveryStatus.pending),
      ),
    );

    store.apply(
      MessageDelta.added(
        _message(
          'local-1',
          DateTime(2026, 9, 19),
        ).copyWith(serverId: 'server-1', status: MessageDeliveryStatus.sent),
      ),
    );

    final messages = store.messagesForRoom('friends');
    expect(messages, hasLength(1));
    expect(messages.single.serverId, 'server-1');
    expect(messages.single.status, MessageDeliveryStatus.sent);
  });

  test('removes message by client or server identity', () {
    final store = MessageStore();
    store.apply(
      MessageDelta.added(
        _message(
          'local-1',
          DateTime(2026, 9, 19),
        ).copyWith(serverId: 'server-1'),
      ),
    );

    store.apply(
      const MessageDelta.removed(roomId: 'friends', serverId: 'server-1'),
    );

    expect(store.messagesForRoom('friends'), isEmpty);
  });
}

ChatMessage _message(String clientId, DateTime createdAt) => ChatMessage(
  clientId: clientId,
  roomId: 'friends',
  senderId: 'Mina',
  content: MessageContent.text(text: clientId),
  status: MessageDeliveryStatus.sent,
  createdAt: createdAt,
);
