import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/media_picker_service.dart';
import '../data/fake/fake_media_upload_data_source.dart';
import '../data/fake/fake_message_event_source.dart';
import '../data/fake/fake_message_remote_data_source.dart';
import '../data/fake/fake_message_repository.dart';
import '../domain/chat_message.dart';
import '../domain/message_content.dart';
import '../domain/message_draft.dart';
import '../domain/message_repository.dart';
import '../domain/message_status.dart';

typedef SendMessage =
    Future<ChatMessage> Function(
      MessageDraft draft, {
      void Function(double progress)? onUploadProgress,
    });

final chatRepositoryProvider = Provider<MessageRepository>((ref) {
  final repository = FakeMessageRepository(
    remote: FakeMessageRemoteDataSource(),
    upload: FakeMediaUploadDataSource(),
    events: FakeMessageEventSource(),
  );
  repository.seedMessages(_seedMessages);
  ref.onDispose(() => unawaited(repository.dispose()));
  return repository;
});

final chatConnectionProvider = FutureProvider.autoDispose<void>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  await repository.connect();
  ref.onDispose(() => unawaited(repository.disconnect()));
});

final roomMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, roomId) async* {
      final repository = ref.watch(chatRepositoryProvider);
      await ref.watch(chatConnectionProvider.future);
      yield await repository.loadMessages(roomId);
      yield* repository.watchRoomMessages(roomId);
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
