import 'dart:async';

import '../message_data_sources.dart';
import '../../domain/chat_message.dart';
import '../../domain/message_connection_state.dart';
import '../../application/message_delta.dart';

class FakeMessageEventSource implements MessageEventSource {
  final StreamController<MessageDelta> _controller =
      StreamController<MessageDelta>.broadcast();
  final StreamController<MessageConnectionState> _stateController =
      StreamController<MessageConnectionState>.broadcast();
  bool _connected = false;

  bool get isConnected => _connected;

  @override
  Stream<MessageDelta> deltas() => _controller.stream;

  @override
  Stream<ChatMessage> events() => deltas()
      .where((delta) => delta is MessageAdded)
      .map((delta) => (delta as MessageAdded).message);

  @override
  Stream<MessageConnectionState> connectionStates() => _stateController.stream;

  @override
  Future<void> connect() async {
    _stateController.add(MessageConnectionState.connecting);
    _connected = true;
    _stateController.add(MessageConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _stateController.add(MessageConnectionState.disconnected);
  }

  void emitIncoming(ChatMessage message) {
    if (_connected) _controller.add(MessageDelta.added(message));
  }

  void emitDuplicate(ChatMessage message) {
    emitIncoming(message);
  }

  void emitModified(ChatMessage message) {
    if (_connected) _controller.add(MessageDelta.modified(message));
  }

  void emitRemoved({
    required String roomId,
    String? clientId,
    String? serverId,
  }) {
    if (_connected) {
      _controller.add(
        MessageDelta.removed(
          roomId: roomId,
          clientId: clientId,
          serverId: serverId,
        ),
      );
    }
  }
}
