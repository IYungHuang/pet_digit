import 'dart:async';

import '../../domain/chat_message.dart';
import '../../domain/message_content.dart';
import '../../domain/message_draft.dart';
import '../../domain/message_repository.dart';
import '../../domain/message_status.dart';
import '../message_data_sources.dart';

class FakeMessageRepository implements MessageRepository {
  FakeMessageRepository({
    required this.remote,
    required this.upload,
    required this.events,
  });

  final MessageRemoteDataSource remote;
  final MediaUploadDataSource upload;
  final MessageEventSource events;

  final Map<String, ChatMessage> _messagesByClientId = {};
  final Map<String, String> _clientIdByServerId = {};
  final Map<String, List<String>> _orderedClientIdsByRoom = {};
  final Map<String, StreamController<List<ChatMessage>>> _roomControllers = {};
  final StreamController<ChatMessage> _incomingController =
      StreamController<ChatMessage>.broadcast();

  StreamSubscription<ChatMessage>? _eventSubscription;
  bool _connected = false;

  @override
  Future<void> connect() async {
    if (_connected) return;
    _eventSubscription = events.events().listen(_handleIncoming);
    _connected = true;
    try {
      await events.connect();
    } catch (_) {
      _connected = false;
      await _eventSubscription?.cancel();
      _eventSubscription = null;
      await events.disconnect();
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    if (!_connected) return;
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await events.disconnect();
    _connected = false;
  }

  @override
  Future<List<ChatMessage>> loadMessages(String roomId) async => [
    for (final clientId in _orderedClientIdsByRoom[roomId] ?? const [])
      _messagesByClientId[clientId]!,
  ];

  void seedMessages(Iterable<ChatMessage> messages) {
    for (final message in messages) {
      _upsert(message);
    }
  }

  @override
  Stream<List<ChatMessage>> watchRoomMessages(String roomId) => _roomControllers
      .putIfAbsent(
        roomId,
        () => StreamController<List<ChatMessage>>.broadcast(),
      )
      .stream;

  @override
  Stream<ChatMessage> watchIncomingMessages() => _incomingController.stream;

  @override
  Future<ChatMessage> send(
    MessageDraft draft, {
    void Function(double progress)? onUploadProgress,
  }) async {
    _upsert(ChatMessage.fromDraft(draft));

    var effectiveDraft = draft;
    if (_requiresUpload(draft.content) && !upload.isAtomicUpload) {
      _update(
        draft.clientId,
        (message) => message.copyWith(
          status: MessageDeliveryStatus.uploading,
          error: null,
          uploadProgress: 0,
        ),
      );
      final uploadedContent = await upload.upload(
        draft,
        onProgress: (progress) {
          onUploadProgress?.call(progress);
          _update(
            draft.clientId,
            (message) => message.copyWith(
              status: MessageDeliveryStatus.uploading,
              uploadProgress: progress,
              error: null,
            ),
          );
        },
      );
      _update(
        draft.clientId,
        (message) => message.copyWith(
          content: uploadedContent,
          status: MessageDeliveryStatus.uploading,
          uploadProgress: 1,
          error: null,
        ),
      );
      effectiveDraft = draft.copyWith(content: uploadedContent);
    }

    _update(
      draft.clientId,
      (message) => message.copyWith(
        status: _requiresUpload(draft.content) && upload.isAtomicUpload
            ? MessageDeliveryStatus.uploading
            : MessageDeliveryStatus.sending,
        error: null,
        uploadProgress: _requiresUpload(draft.content) && upload.isAtomicUpload
            ? 0
            : (_requiresUpload(draft.content) ? 1 : 0),
      ),
    );

    try {
      final receipt = await remote.send(
        effectiveDraft,
        onProgress: (progress) {
          onUploadProgress?.call(progress);
          if (_requiresUpload(draft.content) && upload.isAtomicUpload) {
            _update(
              draft.clientId,
              (message) => message.copyWith(
                status: MessageDeliveryStatus.uploading,
                uploadProgress: progress,
                error: null,
              ),
            );
          }
        },
      );
      return _update(
        draft.clientId,
        (message) => message.copyWith(
          serverId: receipt.serverId,
          serverCreatedAt: receipt.serverCreatedAt,
          status: MessageDeliveryStatus.sent,
          error: null,
          uploadProgress: _requiresUpload(draft.content) ? 1 : 0,
        ),
      );
    } catch (error) {
      _update(
        draft.clientId,
        (message) => message.copyWith(
          status: MessageDeliveryStatus.failed,
          error: error.toString(),
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _incomingController.close();
    for (final controller in _roomControllers.values) {
      await controller.close();
    }
  }

  void _handleIncoming(ChatMessage incoming) {
    final merged = _upsert(incoming);
    _incomingController.add(merged);
  }

  ChatMessage _upsert(ChatMessage message) {
    final existingClientId = message.serverId == null
        ? null
        : _clientIdByServerId[message.serverId!];
    final clientId = existingClientId ?? message.clientId;
    final normalized = clientId == message.clientId
        ? message
        : message.copyWith(clientId: clientId);

    _messagesByClientId[clientId] = normalized;
    if (normalized.serverId != null) {
      _clientIdByServerId[normalized.serverId!] = clientId;
    }

    final roomOrder = _orderedClientIdsByRoom.putIfAbsent(
      normalized.roomId,
      () => <String>[],
    );
    if (!roomOrder.contains(clientId)) roomOrder.add(clientId);
    _emitRoom(normalized.roomId);
    return normalized;
  }

  ChatMessage _update(
    String clientId,
    ChatMessage Function(ChatMessage message) update,
  ) {
    final current = _messagesByClientId[clientId];
    if (current == null) throw StateError('unknown clientId: $clientId');
    return _upsert(update(current));
  }

  void _emitRoom(String roomId) {
    final controller = _roomControllers[roomId];
    if (controller != null && !controller.isClosed) {
      final snapshot = [
        for (final clientId in _orderedClientIdsByRoom[roomId] ?? const [])
          _messagesByClientId[clientId]!,
      ];
      controller.add(snapshot);
    }
  }

  bool _requiresUpload(MessageContent content) => switch (content) {
    ImageMessageContent() || VideoMessageContent() => true,
    TextMessageContent() => false,
  };
}
