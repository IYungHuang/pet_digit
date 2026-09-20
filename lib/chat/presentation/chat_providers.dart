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
      final source = ref.watch(chatEventSourceProvider);
      yield* source.connectionStates();
    });

final chatConnectionProvider = FutureProvider.autoDispose<void>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  await repository.connect();
  ref.onDispose(() => unawaited(repository.disconnect()));
});

final roomMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, roomId) async* {
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
  return ref.watch(chatRepositoryProvider).watchDeltas();
});

final sendMessageProvider = Provider<SendMessage>((ref) {
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
