import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chat_pet_mvp/chat/data/fake/fake_media_upload_data_source.dart';
import 'package:chat_pet_mvp/chat/data/fake/fake_message_event_source.dart';
import 'package:chat_pet_mvp/chat/data/fake/fake_message_remote_data_source.dart';
import 'package:chat_pet_mvp/chat/data/fake/fake_message_repository.dart';
import 'package:chat_pet_mvp/chat/domain/message_draft.dart';
import 'package:chat_pet_mvp/chat/domain/message_status.dart';
import 'package:chat_pet_mvp/chat/domain/message_content.dart';
import 'package:chat_pet_mvp/chat/presentation/chat_providers.dart';

void main() {
  test(
    'connection provider connects and disconnects repository lifecycle',
    () async {
      final events = FakeMessageEventSource();
      final repository = _createRepository(events);
      final container = ProviderContainer(
        overrides: [chatRepositoryProvider.overrideWithValue(repository)],
      );

      addTearDown(() async {
        container.dispose();
        await repository.dispose();
      });

      await container.read(chatConnectionProvider.future);
      expect(events.isConnected, isTrue);

      container.invalidate(chatConnectionProvider);
      await Future<void>.delayed(Duration.zero);
      expect(events.isConnected, isFalse);
    },
  );

  test('room provider emits initial and live room snapshots', () async {
    final events = FakeMessageEventSource();
    final repository = _createRepository(events);
    final container = ProviderContainer(
      overrides: [chatRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      container.dispose();
      await repository.dispose();
    });

    final draft = MessageDraft(
      clientId: 'provider-client',
      roomId: 'friends',
      senderId: 'me',
      content: const MessageContent.text(text: 'hello'),
      createdAt: DateTime(2026, 9, 19),
      isMine: true,
    );

    final values = <List<dynamic>>[];
    final subscription = container.listen<AsyncValue<List<dynamic>>>(
      roomMessagesProvider('friends'),
      (_, next) => next.whenData(values.add),
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.read(roomMessagesProvider('friends').future);
    expect(values, hasLength(1));
    expect(values.single, isEmpty);

    await container.read(sendMessageProvider)(draft);
    await Future<void>.delayed(Duration.zero);
    expect(values.last, hasLength(1));
    expect(values.last.single.status, MessageDeliveryStatus.sent);
  });

  test('connection invalidation preserves room message projection', () async {
    final events = FakeMessageEventSource();
    final repository = _createRepository(events);
    final container = ProviderContainer(
      overrides: [chatRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      container.dispose();
      await repository.dispose();
    });

    final values = <List<dynamic>>[];
    final subscription = container.listen<AsyncValue<List<dynamic>>>(
      roomMessagesProvider('friends'),
      (_, next) => next.whenData(values.add),
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.read(roomMessagesProvider('friends').future);
    await container.read(sendMessageProvider)(
      MessageDraft(
        clientId: 'persist-client',
        roomId: 'friends',
        senderId: 'me',
        content: const MessageContent.text(text: 'persist'),
        createdAt: DateTime(2026, 9, 19),
        isMine: true,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(values.last, hasLength(1));

    container.invalidate(chatConnectionProvider);
    await Future<void>.delayed(Duration.zero);

    expect(values.last, hasLength(1));
    expect(values.last.single.clientId, 'persist-client');
  });

  test(
    'send provider delegates upload progress and returns sent message',
    () async {
      final events = FakeMessageEventSource();
      final repository = _createRepository(events);
      final container = ProviderContainer(
        overrides: [chatRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() async {
        container.dispose();
        await repository.dispose();
      });

      final progress = <double>[];
      final draft = MessageDraft(
        clientId: 'provider-image',
        roomId: 'friends',
        senderId: 'me',
        content: const MessageContent.image(
          url: 'file:///tmp/photo.jpg',
          mimeType: 'image/jpeg',
        ),
        createdAt: DateTime(2026, 9, 19),
        isMine: true,
      );

      final message = await container.read(sendMessageProvider)(
        draft,
        onUploadProgress: progress.add,
      );

      expect(message.status, MessageDeliveryStatus.sent);
      expect(progress, [0.25, 0.5, 0.75, 1.0]);
    },
  );

  test('media picker provider resolves default picker service', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final picker = container.read(mediaPickerServiceProvider);
    expect(picker, isNotNull);
  });
}

FakeMessageRepository _createRepository(FakeMessageEventSource events) =>
    FakeMessageRepository(
      remote: FakeMessageRemoteDataSource(latency: Duration.zero),
      upload: FakeMediaUploadDataSource(latency: Duration.zero),
      events: events,
    );
