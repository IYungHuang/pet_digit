import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chat_pet_mvp/chat/data/fake/fake_media_upload_data_source.dart';
import 'package:chat_pet_mvp/chat/data/fake/fake_message_event_source.dart';
import 'package:chat_pet_mvp/chat/data/fake/fake_message_remote_data_source.dart';
import 'package:chat_pet_mvp/chat/data/fake/fake_message_repository.dart';
import 'package:chat_pet_mvp/chat/domain/message_connection_state.dart';
import 'package:chat_pet_mvp/chat/domain/message_draft.dart';
import 'package:chat_pet_mvp/chat/domain/message_status.dart';
import 'package:chat_pet_mvp/chat/domain/message_content.dart';
import 'package:chat_pet_mvp/chat/presentation/chat_providers.dart';
import 'package:chat_pet_mvp/firebase/firebase_environment.dart';

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

  test('membership status is notRequired outside staging', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(stagingMembershipControllerProvider),
      StagingMembershipStatus.notRequired,
    );
  });

  test(
    'membership controller transitions waiting -> checking -> ready on success',
    () async {
      final container = ProviderContainer(
        overrides: [
          firebaseEnvironmentProvider.overrideWithValue(
            const FirebaseEnvironment(mode: FirebaseEnvironmentMode.staging),
          ),
          roomMembershipProbeProvider.overrideWithValue((_) async {}),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        stagingMembershipControllerProvider.notifier,
      );
      expect(
        container.read(stagingMembershipControllerProvider),
        StagingMembershipStatus.waiting,
      );

      final checking = controller.verify('friends');
      expect(
        container.read(stagingMembershipControllerProvider),
        StagingMembershipStatus.checking,
      );

      final result = await checking;
      expect(result, isTrue);
      expect(
        container.read(stagingMembershipControllerProvider),
        StagingMembershipStatus.ready,
      );
    },
  );

  test(
    'membership controller transitions waiting -> checking -> denied on permission-denied',
    () async {
      final container = ProviderContainer(
        overrides: [
          firebaseEnvironmentProvider.overrideWithValue(
            const FirebaseEnvironment(mode: FirebaseEnvironmentMode.staging),
          ),
          roomMembershipProbeProvider.overrideWithValue((_) async {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        stagingMembershipControllerProvider.notifier,
      );

      final checking = controller.verify('friends');
      expect(
        container.read(stagingMembershipControllerProvider),
        StagingMembershipStatus.checking,
      );

      final result = await checking;
      expect(result, isFalse);
      expect(
        container.read(stagingMembershipControllerProvider),
        StagingMembershipStatus.denied,
      );
    },
  );

  test(
    'gated providers do not reach the repository while membership is not ready',
    () async {
      final events = FakeMessageEventSource();
      final repository = _createRepository(events);
      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(repository),
          stagingMembershipControllerProvider.overrideWith(
            (ref) => StagingMembershipController(
              initialState: StagingMembershipStatus.waiting,
              probe: (_) async {},
            ),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await repository.dispose();
      });

      await container.read(chatConnectionProvider.future);
      expect(events.isConnected, isFalse);

      final messagesSub = container.listen<AsyncValue<List<dynamic>>>(
        roomMessagesProvider('friends'),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(messagesSub.close);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(roomMessagesProvider('friends')).isLoading, isTrue);
      expect(events.isConnected, isFalse);

      final connectionSub = container
          .listen<AsyncValue<MessageConnectionState>>(
            messageConnectionStateProvider,
            (_, __) {},
            fireImmediately: true,
          );
      addTearDown(connectionSub.close);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(messageConnectionStateProvider).value,
        MessageConnectionState.disconnected,
      );

      final deltaSub = container.listen<AsyncValue<dynamic>>(
        messageDeltaProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(deltaSub.close);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(messageDeltaProvider).isLoading, isTrue);

      await expectLater(
        container.read(sendMessageProvider)(
          MessageDraft(
            clientId: 'blocked',
            roomId: 'friends',
            senderId: 'me',
            content: const MessageContent.text(text: 'blocked'),
            createdAt: DateTime(2026, 9, 19),
            isMine: true,
          ),
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'failed re-verification does not clear the cached room projection',
    () async {
      final events = FakeMessageEventSource();
      final repository = _createRepository(events);
      var shouldFail = false;
      final container = ProviderContainer(
        overrides: [
          chatEventSourceProvider.overrideWithValue(events),
          chatRepositoryProvider.overrideWithValue(repository),
          firebaseEnvironmentProvider.overrideWithValue(
            const FirebaseEnvironment(mode: FirebaseEnvironmentMode.staging),
          ),
          roomMembershipProbeProvider.overrideWithValue((_) async {
            if (shouldFail) {
              throw FirebaseException(
                plugin: 'cloud_firestore',
                code: 'permission-denied',
              );
            }
          }),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await repository.dispose();
      });

      final controller = container.read(
        stagingMembershipControllerProvider.notifier,
      );
      expect(await controller.verify('friends'), isTrue);

      container.invalidate(roomMessagesProvider('friends'));
      container.invalidate(chatConnectionProvider);
      container.invalidate(sendMessageProvider);

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
          clientId: 'persisted',
          roomId: 'friends',
          senderId: 'me',
          content: const MessageContent.text(text: 'persisted'),
          createdAt: DateTime(2026, 9, 19),
          isMine: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(values.last, hasLength(1));

      shouldFail = true;
      final result = await controller.verify('friends');
      expect(result, isFalse);
      await Future<void>.delayed(Duration.zero);

      expect(values.last, hasLength(1));
      expect(values.last.single.clientId, 'persisted');
    },
  );

  group('isActiveRoomMember', () {
    test('missing membership document is not an active member', () {
      expect(isActiveRoomMember(false, null), isFalse);
    });

    test('membership document with active: false is not an active member', () {
      expect(isActiveRoomMember(true, {'active': false}), isFalse);
    });

    test(
      'membership document without an active key is not an active member',
      () {
        expect(isActiveRoomMember(true, {'other': 1}), isFalse);
      },
    );

    test('membership document with active: true is an active member', () {
      expect(isActiveRoomMember(true, {'active': true}), isTrue);
    });
  });

  test(
    'probe throws StateError when the staging user is not authenticated',
    () async {
      final container = ProviderContainer(
        overrides: [
          firebaseEnvironmentProvider.overrideWithValue(
            const FirebaseEnvironment(mode: FirebaseEnvironmentMode.staging),
          ),
          firebaseFirestoreProvider.overrideWithValue(_UnusedFakeFirestore()),
          firebaseAuthProvider.overrideWithValue(_FakeAuthWithoutUser()),
        ],
      );
      addTearDown(container.dispose);

      final probe = container.read(roomMembershipProbeProvider);
      await expectLater(probe('friends'), throwsA(isA<StateError>()));
    },
  );
}

FakeMessageRepository _createRepository(FakeMessageEventSource events) =>
    FakeMessageRepository(
      remote: FakeMessageRemoteDataSource(latency: Duration.zero),
      upload: FakeMediaUploadDataSource(latency: Duration.zero),
      events: events,
    );

/// Minimal [FirebaseAuth] fake with no signed-in user, so the probe's
/// `uid == null` guard is exercised without a real Firebase app.
class _FakeAuthWithoutUser implements FirebaseAuth {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Placeholder [FirebaseFirestore] fake that is never actually read: the
/// probe throws on the `uid == null` guard before touching Firestore, so
/// this only needs to satisfy the non-null provider type.
class _UnusedFakeFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
