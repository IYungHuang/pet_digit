import 'dart:async';

import '../../domain/chat_message.dart';
import '../../domain/message_content.dart';
import '../../domain/message_draft.dart';
import '../../domain/message_repository.dart';
import '../../domain/message_status.dart';
import '../message_data_sources.dart';
import '../../application/message_delta.dart';
import '../../application/message_store.dart';

class FakeMessageRepository implements MessageRepository {
  FakeMessageRepository({
    required this.remote,
    required this.upload,
    required this.events,
  });

  final MessageRemoteDataSource remote;
  final MediaUploadDataSource upload;
  final MessageEventSource events;

  final MessageStore _store = MessageStore();
  final Map<String, StreamController<List<ChatMessage>>> _roomControllers = {};
  final StreamController<MessageDelta> _deltaController =
      StreamController<MessageDelta>.broadcast();
  final StreamController<ChatMessage> _incomingController =
      StreamController<ChatMessage>.broadcast();

  StreamSubscription<MessageDelta>? _eventSubscription;
  bool _connected = false;

  @override
  Future<void> connect() async {
    if (_connected) return;
    _eventSubscription = events.deltas().listen(_handleDelta);
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
  Future<void> reconnect() async {
    await disconnect();
    await connect();
  }

  @override
  Future<List<ChatMessage>> loadMessages(String roomId) async =>
      _store.messagesForRoom(roomId);

  void seedMessages(Iterable<ChatMessage> messages) {
    _store.mergeInitial(messages);
  }

  @override
  Stream<List<ChatMessage>> watchRoomMessages(String roomId) => _roomControllers
      .putIfAbsent(
        roomId,
        () => StreamController<List<ChatMessage>>.broadcast(),
      )
      .stream;

  @override
  Stream<MessageDelta> watchDeltas() => _deltaController.stream;

  @override
  Stream<ChatMessage> watchIncomingMessages() => _incomingController.stream;

  @override
  Future<ChatMessage> send(
    MessageDraft draft, {
    void Function(double progress)? onUploadProgress,
  }) async {
    _applyDelta(
      MessageDelta.added(
        ChatMessage.fromDraft(draft),
        origin: MessageAddedOrigin.localOptimistic,
      ),
    );

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
    await _deltaController.close();
    for (final controller in _roomControllers.values) {
      await controller.close();
    }
  }

  void _handleDelta(MessageDelta delta) {
    _applyDelta(delta);
  }

  void _applyDelta(MessageDelta delta) {
    _store.apply(delta);
    _deltaController.add(delta);
    final roomId = switch (delta) {
      MessageAdded(:final message) => message.roomId,
      MessageModified(:final message) => message.roomId,
      MessageRemoved(:final roomId) => roomId,
    };
    final message = switch (delta) {
      MessageAdded(:final message) => message,
      MessageModified(:final message) => message,
      MessageRemoved() => null,
    };
    if (message != null) _incomingController.add(message);
    _emitRoom(roomId);
  }

  ChatMessage _update(
    String clientId,
    ChatMessage Function(ChatMessage message) update,
  ) {
    final current = _store.messageByClientId(clientId);
    if (current == null) throw StateError('unknown clientId: $clientId');
    final next = update(current);
    _applyDelta(MessageDelta.modified(next));
    return _store.messageByClientId(next.clientId)!;
  }

  void _emitRoom(String roomId) {
    final controller = _roomControllers[roomId];
    if (controller != null && !controller.isClosed) {
      controller.add(_store.messagesForRoom(roomId));
    }
  }

  bool _requiresUpload(MessageContent content) => switch (content) {
    ImageMessageContent() || VideoMessageContent() => true,
    TextMessageContent() => false,
  };
}
