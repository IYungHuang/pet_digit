import 'dart:async';

import '../message_data_sources.dart';
import '../../domain/chat_message.dart';
import '../../domain/message_connection_state.dart';

class FakeMessageEventSource implements MessageEventSource {
  final StreamController<ChatMessage> _controller =
      StreamController<ChatMessage>.broadcast();
  final StreamController<MessageConnectionState> _stateController =
      StreamController<MessageConnectionState>.broadcast();
  bool _connected = false;

  bool get isConnected => _connected;

  @override
  Stream<ChatMessage> events() => _controller.stream;

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
    if (_connected) _controller.add(message);
  }

  void emitDuplicate(ChatMessage message) {
    emitIncoming(message);
  }
}
