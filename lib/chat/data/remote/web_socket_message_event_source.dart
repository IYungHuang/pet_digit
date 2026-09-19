import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../domain/chat_message.dart';
import '../../domain/message_connection_state.dart';
import '../message_data_sources.dart';
import 'remote_message_mapper.dart';

typedef WebSocketConnector = WebSocketChannel Function(Uri uri);

/// Adapts Gespraach's JSON WebSocket stream to domain message events.
class WebSocketMessageEventSource implements MessageEventSource {
  WebSocketMessageEventSource({
    required this.uri,
    this.connector = WebSocketChannel.connect,
    this.reconnectBaseDelay = const Duration(seconds: 1),
    this.maxReconnectAttempts = 5,
  });

  final Uri uri;
  final WebSocketConnector connector;
  final Duration reconnectBaseDelay;
  final int maxReconnectAttempts;
  final StreamController<ChatMessage> _events =
      StreamController<ChatMessage>.broadcast();
  final StreamController<MessageConnectionState> _states =
      StreamController<MessageConnectionState>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  var _manualDisconnect = false;
  var _reconnectAttempt = 0;
  var _generation = 0;
  var _isReady = false;
  Future<void>? _connectFuture;

  bool get isConnected => _isReady;

  @override
  Stream<ChatMessage> events() => _events.stream;

  @override
  Stream<MessageConnectionState> connectionStates() => _states.stream;

  @override
  Future<void> connect() async {
    final pending = _connectFuture;
    if (pending != null) return pending;
    if (_channel != null) return;
    _manualDisconnect = false;
    final future = _open(isReconnect: false);
    _connectFuture = future;
    try {
      await future;
    } finally {
      if (identical(_connectFuture, future)) _connectFuture = null;
    }
  }

  Future<void> _open({required bool isReconnect}) async {
    if (_channel != null) return;
    final generation = ++_generation;
    _states.add(
      isReconnect
          ? MessageConnectionState.reconnecting
          : MessageConnectionState.connecting,
    );
    WebSocketChannel? channel;
    try {
      channel = connector(uri);
      _channel = channel;
      await channel.ready;
      if (generation != _generation || _manualDisconnect) {
        await channel.sink.close();
        return;
      }
      _reconnectAttempt = 0;
      _isReady = true;
      _states.add(MessageConnectionState.connected);
      _subscription = channel.stream.listen(
        (frame) {
          if (generation == _generation && identical(_channel, channel)) {
            _handleFrame(frame);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (generation != _generation) return;
          _states.add(MessageConnectionState.error);
          _events.addError(error, stackTrace);
          _channel = null;
          _isReady = false;
          final subscription = _subscription;
          _subscription = null;
          unawaited(subscription?.cancel());
          unawaited(channel!.sink.close());
          if (!_manualDisconnect) _scheduleReconnect();
        },
        onDone: () {
          if (generation != _generation) return;
          _channel = null;
          _isReady = false;
          _subscription = null;
          if (!_manualDisconnect) {
            _scheduleReconnect();
          } else {
            _states.add(MessageConnectionState.disconnected);
          }
        },
      );
    } catch (error, stackTrace) {
      if (identical(_channel, channel)) _channel = null;
      _isReady = false;
      await channel?.sink.close();
      if (generation != _generation || _manualDisconnect) return;
      _states.add(MessageConnectionState.error);
      if (!isReconnect) Error.throwWithStackTrace(error, stackTrace);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _reconnectTimer != null) return;
    if (_reconnectAttempt >= maxReconnectAttempts) {
      _states.add(MessageConnectionState.offline);
      return;
    }
    _reconnectAttempt++;
    final multiplier = 1 << (_reconnectAttempt - 1);
    final delay = reconnectBaseDelay * multiplier;
    _states.add(MessageConnectionState.reconnecting);
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      _open(isReconnect: true);
    });
  }

  @override
  Future<void> disconnect() async {
    _manualDisconnect = true;
    _generation++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    final channel = _channel;
    _channel = null;
    _isReady = false;
    await channel?.sink.close();
    _states.add(MessageConnectionState.disconnected);
  }

  void _handleFrame(dynamic frame) {
    try {
      final decoded = jsonDecode('$frame');
      if (decoded is! Map) return;
      final message = RemoteMessageMapper.fromWebSocket(
        Map<String, dynamic>.from(decoded),
      );
      if (message != null) _events.add(message);
    } on Object catch (error, stackTrace) {
      _events.addError(error, stackTrace);
    }
  }
}
