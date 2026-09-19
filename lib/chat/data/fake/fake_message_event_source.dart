import 'dart:async';

import '../message_data_sources.dart';
import '../../domain/chat_message.dart';

class FakeMessageEventSource implements MessageEventSource {
  final StreamController<ChatMessage> _controller =
      StreamController<ChatMessage>.broadcast();
  bool _connected = false;

  bool get isConnected => _connected;

  @override
  Stream<ChatMessage> events() => _controller.stream;

  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  void emitIncoming(ChatMessage message) {
    if (_connected) _controller.add(message);
  }

  void emitDuplicate(ChatMessage message) {
    emitIncoming(message);
  }
}
