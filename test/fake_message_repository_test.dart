import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/chat/data/fake/fake_media_upload_data_source.dart';
import 'package:chat_pet_mvp/chat/data/fake/fake_message_event_source.dart';
import 'package:chat_pet_mvp/chat/data/fake/fake_message_remote_data_source.dart';
import 'package:chat_pet_mvp/chat/data/fake/fake_message_repository.dart';
import 'package:chat_pet_mvp/chat/domain/chat_message.dart';
import 'package:chat_pet_mvp/chat/domain/message_content.dart';
import 'package:chat_pet_mvp/chat/domain/message_draft.dart';
import 'package:chat_pet_mvp/chat/domain/message_status.dart';

void main() {
  late FakeMessageRemoteDataSource remote;
  late FakeMediaUploadDataSource upload;
  late FakeMessageEventSource events;
  late FakeMessageRepository repository;

  setUp(() async {
    remote = FakeMessageRemoteDataSource(
      latency: const Duration(milliseconds: 1),
    );
    upload = FakeMediaUploadDataSource(
      latency: const Duration(milliseconds: 1),
    );
    events = FakeMessageEventSource();
    repository = FakeMessageRepository(
      remote: remote,
      upload: upload,
      events: events,
    );
    await repository.connect();
  });

  tearDown(() async {
    await repository.disconnect();
  });

  test('text send emits pending before sent', () async {
    final emissions = <List<ChatMessage>>[];
    final subscription = repository
        .watchRoomMessages('room-1')
        .listen(emissions.add);

    final future = repository.send(_textDraft());
    await Future<void>.delayed(Duration.zero);
    expect(emissions.first.single.status, MessageDeliveryStatus.pending);

    final sent = await future;
    await Future<void>.delayed(Duration.zero);

    expect(sent.status, MessageDeliveryStatus.sent);
    expect(sent.serverId, isNotNull);
    expect(emissions.last.single.clientId, sent.clientId);
    expect(emissions.last.single.status, MessageDeliveryStatus.sent);
    await subscription.cancel();
  });

  test('media send reports progress and ends sent', () async {
    final progress = <double>[];
    final draft = MessageDraft(
      clientId: 'client-image',
      roomId: 'room-1',
      senderId: 'user-1',
      content: const MessageContent.image(
        url: '',
        mimeType: 'image/png',
        localPath: '/tmp/photo.png',
      ),
      createdAt: DateTime.utc(2026, 9, 19),
      isMine: true,
    );

    final sent = await repository.send(draft, onUploadProgress: progress.add);

    expect(progress, [0.25, 0.5, 0.75, 1.0]);
    expect(sent.status, MessageDeliveryStatus.sent);
    expect(sent.content, isA<ImageMessageContent>());
    expect(
      (sent.content as ImageMessageContent).url,
      'fake://media/client-image',
    );
  });

  test('failed send can retry without duplicating client message', () async {
    remote.failNextSend = true;

    await expectLater(
      repository.send(_textDraft(clientId: 'retry-client')),
      throwsA(isA<StateError>()),
    );

    final failed = await repository.loadMessages('room-1');
    expect(failed, hasLength(1));
    expect(failed.single.clientId, 'retry-client');
    expect(failed.single.status, MessageDeliveryStatus.failed);

    final sent = await repository.send(_textDraft(clientId: 'retry-client'));
    final messages = await repository.loadMessages('room-1');

    expect(sent.status, MessageDeliveryStatus.sent);
    expect(messages, hasLength(1));
    expect(messages.single.serverId, sent.serverId);
  });

  test('duplicate incoming event does not duplicate room message', () async {
    final incoming = ChatMessage(
      clientId: 'incoming-client',
      serverId: 'server-1',
      roomId: 'room-1',
      senderId: 'other-user',
      content: const MessageContent.text(text: 'hello'),
      status: MessageDeliveryStatus.sent,
      createdAt: DateTime.utc(2026, 9, 19),
      isMine: false,
    );

    events.emitIncoming(incoming);
    events.emitDuplicate(incoming);
    await Future<void>.delayed(Duration.zero);

    final messages = await repository.loadMessages('room-1');
    expect(messages, hasLength(1));
    expect(messages.single.serverId, 'server-1');
  });

  test('events emitted while disconnected are ignored', () async {
    await repository.disconnect();
    events.emitIncoming(_incoming('server-before-connect'));
    await Future<void>.delayed(Duration.zero);
    expect(await repository.loadMessages('room-1'), isEmpty);

    await repository.connect();
    events.emitIncoming(_incoming('server-after-connect'));
    await Future<void>.delayed(Duration.zero);
    expect(await repository.loadMessages('room-1'), hasLength(1));
  });
}

MessageDraft _textDraft({String clientId = 'client-text'}) => MessageDraft(
  clientId: clientId,
  roomId: 'room-1',
  senderId: 'user-1',
  content: const MessageContent.text(text: 'hello'),
  createdAt: DateTime.utc(2026, 9, 19),
  isMine: true,
);

ChatMessage _incoming(String serverId) => ChatMessage(
  clientId: 'client-$serverId',
  serverId: serverId,
  roomId: 'room-1',
  senderId: 'other-user',
  content: const MessageContent.text(text: 'incoming'),
  status: MessageDeliveryStatus.sent,
  createdAt: DateTime.utc(2026, 9, 19),
  isMine: false,
);
