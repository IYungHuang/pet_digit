import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../application/media_picker_service.dart';
import '../application/message_delta.dart';
import '../data/fake/fake_media_upload_data_source.dart';
import '../data/fake/fake_message_event_source.dart';
import '../data/fake/fake_message_remote_data_source.dart';
import '../data/fake/fake_message_repository.dart';
import '../data/message_data_sources.dart';
import '../data/firebase/firebase_media_upload_data_source.dart';
import '../data/firebase/firebase_message_event_source.dart';
import '../data/firebase/firebase_message_remote_data_source.dart';
import '../data/firebase/firebase_message_repository.dart';
import '../domain/chat_message.dart';
import '../domain/message_content.dart';
import '../domain/message_draft.dart';
import '../domain/message_repository.dart';
import '../domain/message_status.dart';
import '../domain/message_connection_state.dart';
import '../../firebase/firebase_environment.dart';

typedef SendMessage =
    Future<ChatMessage> Function(
      MessageDraft draft, {
      void Function(double progress)? onUploadProgress,
    });

/// Membership-gated access state for staging chat rooms. Fake and emulator
/// transports never require a membership probe and stay [notRequired].
enum StagingMembershipStatus { notRequired, waiting, checking, ready, denied }

/// Verifies that the current Firebase user has active membership in
/// `rooms/{roomId}/members/{uid}`. Throws when access is not granted.
typedef RoomMembershipProbe = Future<void> Function(String roomId);

/// Drives the staging room access state machine: `waiting` until the caller
/// requests [verify], `checking` while the probe runs, then `ready` or
/// `denied` depending on the probe result. Never marks `ready` before the
/// probe has actually succeeded.
class StagingMembershipController
    extends StateNotifier<StagingMembershipStatus> {
  StagingMembershipController({
    required StagingMembershipStatus initialState,
    required RoomMembershipProbe probe,
  }) : _probe = probe,
       super(initialState);

  final RoomMembershipProbe _probe;

  /// Runs the membership probe for [roomId]. Returns `true` only once state
  /// has become [StagingMembershipStatus.ready]; any failure (permission
  /// denied, missing/inactive membership, or any other error) transitions to
  /// [StagingMembershipStatus.denied] and returns `false`.
  Future<bool> verify(String roomId) async {
    state = StagingMembershipStatus.checking;
    try {
      await _probe(roomId);
      state = StagingMembershipStatus.ready;
      return true;
    } catch (_) {
      state = StagingMembershipStatus.denied;
      return false;
    }
  }

  /// Resets back to [StagingMembershipStatus.waiting], e.g. when the UI
  /// switches to a room whose membership has never been verified. Callers
  /// must invalidate the room-scoped providers themselves afterward so they
  /// re-evaluate against the reset gate.
  void reset() {
    state = StagingMembershipStatus.waiting;
  }
}

final firebaseEnvironmentProvider = Provider<FirebaseEnvironment>(
  (ref) => FirebaseEnvironment.fromDartDefine(),
);

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  final environment = ref.watch(firebaseEnvironmentProvider);
  return environment.usesBackendTransport ? FirebaseAuth.instance : null;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore?>((ref) {
  final environment = ref.watch(firebaseEnvironmentProvider);
  return environment.usesBackendTransport ? FirebaseFirestore.instance : null;
});

final firebaseStorageProvider = Provider<FirebaseStorage?>((ref) {
  final environment = ref.watch(firebaseEnvironmentProvider);
  return environment.usesBackendTransport ? FirebaseStorage.instance : null;
});

final firebaseFunctionsProvider = Provider<FirebaseFunctions?>((ref) {
  final environment = ref.watch(firebaseEnvironmentProvider);
  return environment.usesBackendTransport
      ? FirebaseFunctions.instanceFor(region: firebaseFunctionsRegion)
      : null;
});

final chatEventSourceProvider = Provider<MessageEventSource>((ref) {
  if (ref.watch(useBackendTransportProvider)) {
    return ref.watch(backendEventSourceProvider);
  }
  return FakeMessageEventSource();
});

final useBackendTransportProvider = Provider<bool>((ref) {
  return ref.watch(firebaseEnvironmentProvider).usesBackendTransport;
});

/// Pure access decision for a `rooms/{roomId}/members/{uid}` document read:
/// membership is active only when the document exists and its `active`
/// field is exactly `true`. Extracted so the predicate itself is directly
/// unit-testable without standing up Firestore.
bool isActiveRoomMember(bool docExists, Map<String, dynamic>? data) {
  return docExists && data?['active'] == true;
}

/// Reads `rooms/{roomId}/members/{currentUid}` and succeeds only when the
/// document exists with `active == true`. Outside staging this is a no-op:
/// the controller never needs to call it because it starts `notRequired`.
final roomMembershipProbeProvider = Provider<RoomMembershipProbe>((ref) {
  final environment = ref.watch(firebaseEnvironmentProvider);
  if (environment.mode != FirebaseEnvironmentMode.staging) {
    return (_) async {};
  }
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  if (firestore == null || auth == null) {
    throw StateError('Staging Firebase providers are unavailable');
  }
  return (roomId) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw StateError('Staging user is not authenticated');
    final member = await firestore.doc('rooms/$roomId/members/$uid').get();
    if (!isActiveRoomMember(member.exists, member.data())) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Active room membership is required',
      );
    }
  };
});

final stagingMembershipControllerProvider =
    StateNotifierProvider<StagingMembershipController, StagingMembershipStatus>(
      (ref) {
        final environment = ref.watch(firebaseEnvironmentProvider);
        return StagingMembershipController(
          initialState: environment.mode == FirebaseEnvironmentMode.staging
              ? StagingMembershipStatus.waiting
              : StagingMembershipStatus.notRequired,
          probe: ref.watch(roomMembershipProbeProvider),
        );
      },
    );

/// True once staging room access has been proven (or is not required, i.e.
/// fake/emulator transports). Reads the controller state as a snapshot: a
/// later denial does not retroactively tear down providers built while
/// access was allowed — callers must explicitly invalidate on success.
bool _roomAccessAllowed(Ref ref) {
  final status = ref.read(stagingMembershipControllerProvider);
  return status == StagingMembershipStatus.ready ||
      status == StagingMembershipStatus.notRequired;
}

final backendEventSourceProvider = Provider<MessageEventSource>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  if (firestore == null || auth == null) {
    throw StateError(
      'Firebase emulator providers require initialized Firebase',
    );
  }
  return FirebaseMessageEventSource(firestore: firestore, auth: auth);
});

final backendRemoteDataSourceProvider = Provider<MessageRemoteDataSource>((
  ref,
) {
  final functions = ref.watch(firebaseFunctionsProvider);
  final auth = ref.watch(firebaseAuthProvider);
  if (functions == null || auth == null) {
    throw StateError(
      'Firebase emulator providers require initialized Firebase',
    );
  }
  return FirebaseMessageRemoteDataSource(functions: functions, auth: auth);
});

final backendUploadDataSourceProvider = Provider<MediaUploadDataSource>((ref) {
  final storage = ref.watch(firebaseStorageProvider);
  final auth = ref.watch(firebaseAuthProvider);
  if (storage == null || auth == null) {
    throw StateError(
      'Firebase emulator providers require initialized Firebase',
    );
  }
  return FirebaseMediaUploadDataSource(storage: storage, auth: auth);
});

final chatRepositoryProvider = Provider<MessageRepository>((ref) {
  final useBackend = ref.watch(useBackendTransportProvider);
  late final MessageRepository repository;
  if (useBackend) {
    repository = FirebaseMessageRepository(
      remote: ref.watch(backendRemoteDataSourceProvider),
      upload: ref.watch(backendUploadDataSourceProvider),
      events: ref.watch(chatEventSourceProvider) as FirebaseMessageEventSource,
    );
  } else {
    final fakeRepository = FakeMessageRepository(
      remote: FakeMessageRemoteDataSource(),
      upload: FakeMediaUploadDataSource(),
      events: ref.watch(chatEventSourceProvider),
    );
    fakeRepository.seedMessages(_seedMessages);
    repository = fakeRepository;
  }
  ref.onDispose(() => unawaited(repository.dispose()));
  return repository;
});

/// Production composition seam. App bootstrap must override Dio and URI with
/// authenticated instances; demo/tests intentionally keep [chatRepositoryProvider]
/// fake-first.
final backendDioProvider = Provider<Dio>(
  (ref) => throw StateError('backendDioProvider requires app composition'),
);

final backendWebSocketUriProvider = Provider<Uri>(
  (ref) =>
      throw StateError('backendWebSocketUriProvider requires app composition'),
);

final messageConnectionStateProvider =
    StreamProvider.autoDispose<MessageConnectionState>((ref) async* {
      if (!_roomAccessAllowed(ref)) {
        yield MessageConnectionState.disconnected;
        return;
      }
      final source = ref.watch(chatEventSourceProvider);
      yield* source.connectionStates();
    });

final chatConnectionProvider = FutureProvider.autoDispose<void>((ref) async {
  if (!_roomAccessAllowed(ref)) return;
  final repository = ref.watch(chatRepositoryProvider);
  await repository.connect();
  ref.onDispose(() => unawaited(repository.disconnect()));
});

final roomMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, roomId) async* {
      if (!_roomAccessAllowed(ref)) return;
      final repository = ref.watch(chatRepositoryProvider);
      final source = ref.watch(chatEventSourceProvider);
      if (source is FirebaseMessageEventSource) {
        await source.setActiveRoom(roomId);
      }
      await repository.connect();
      yield await repository.loadMessages(roomId);
      await for (final messages in repository.watchRoomMessages(roomId)) {
        yield messages;
      }
    });

final messageDeltaProvider = StreamProvider.autoDispose<MessageDelta>((ref) {
  if (!_roomAccessAllowed(ref)) return const Stream<MessageDelta>.empty();
  return ref.watch(chatRepositoryProvider).watchDeltas();
});

final sendMessageProvider = Provider<SendMessage>((ref) {
  if (!_roomAccessAllowed(ref)) {
    return (draft, {onUploadProgress}) =>
        Future<ChatMessage>.error(StateError('Room membership is not ready'));
  }
  final repository = ref.watch(chatRepositoryProvider);
  return (draft, {onUploadProgress}) =>
      repository.send(draft, onUploadProgress: onUploadProgress);
});

final mediaPickerServiceProvider = Provider<MediaPickerService>((ref) {
  return NativeMediaPickerService();
});

final _seedMessages = <ChatMessage>[
  ChatMessage(
    clientId: 'f1',
    serverId: 'seed-f1',
    roomId: 'friends',
    senderId: 'Mina',
    content: const MessageContent.text(text: 'Look who joined us!'),
    status: MessageDeliveryStatus.sent,
    createdAt: DateTime(2026, 9, 19, 8),
  ),
  ChatMessage(
    clientId: 'f2',
    serverId: 'seed-f2',
    roomId: 'friends',
    senderId: 'You',
    content: const MessageContent.text(text: '👋'),
    status: MessageDeliveryStatus.sent,
    createdAt: DateTime(2026, 9, 19, 8, 1),
    isMine: true,
  ),
  ChatMessage(
    clientId: 'f3',
    serverId: 'seed-f3',
    roomId: 'friends',
    senderId: 'Mina',
    content: const MessageContent.image(
      url: 'Corgi dance.gif',
      mimeType: 'image/gif',
    ),
    status: MessageDeliveryStatus.sent,
    createdAt: DateTime(2026, 9, 19, 8, 2),
  ),
  ChatMessage(
    clientId: 'f4',
    serverId: 'seed-f4',
    roomId: 'friends',
    senderId: 'You',
    content: const MessageContent.text(text: 'This chat has a tiny world.'),
    status: MessageDeliveryStatus.sent,
    createdAt: DateTime(2026, 9, 19, 8, 3),
    isMine: true,
  ),
  for (var index = 0; index < 8; index++)
    ChatMessage(
      clientId: 'f-extra-$index',
      serverId: 'seed-f-extra-$index',
      roomId: 'friends',
      senderId: index.isEven ? 'Mina' : 'You',
      content: MessageContent.text(
        text: index.isEven
            ? 'The tiny world is still moving.'
            : 'I can see the pets reacting.',
      ),
      status: MessageDeliveryStatus.sent,
      createdAt: DateTime(2026, 9, 19, 8, 4),
      isMine: index.isOdd,
    ),
  ChatMessage(
    clientId: 'a1',
    serverId: 'seed-a1',
    roomId: 'family',
    senderId: 'Dad',
    content: const MessageContent.text(text: 'Dinner at 7?'),
    status: MessageDeliveryStatus.sent,
    createdAt: DateTime(2026, 9, 19, 8),
  ),
  ChatMessage(
    clientId: 'a2',
    serverId: 'seed-a2',
    roomId: 'family',
    senderId: 'You',
    content: const MessageContent.text(text: '🍜'),
    status: MessageDeliveryStatus.sent,
    createdAt: DateTime(2026, 9, 19, 8, 1),
    isMine: true,
  ),
  ChatMessage(
    clientId: 'a3',
    serverId: 'seed-a3',
    roomId: 'family',
    senderId: 'Grandma',
    content: const MessageContent.image(
      url: 'Cat video.gif',
      mimeType: 'image/gif',
    ),
    status: MessageDeliveryStatus.sent,
    createdAt: DateTime(2026, 9, 19, 8, 2),
  ),
];
