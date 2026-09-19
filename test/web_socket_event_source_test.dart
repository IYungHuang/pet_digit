import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:chat_pet_mvp/chat/data/remote/web_socket_message_event_source.dart';
import 'package:chat_pet_mvp/chat/domain/message_connection_state.dart';

void main() {
  test(
    'disconnect during handshake prevents stale channel activation',
    () async {
      final channel = _TestChannel();
      final source = WebSocketMessageEventSource(
        uri: Uri.parse('wss://example.test'),
        connector: (_) => channel,
      );
      final states = <MessageConnectionState>[];
      final subscription = source.connectionStates().listen(states.add);
      final connecting = source.connect();

      await source.disconnect();
      channel.readyCompleter.complete();
      await connecting;

      expect(states, contains(MessageConnectionState.disconnected));
      expect(states, isNot(contains(MessageConnectionState.connected)));
      await subscription.cancel();
    },
  );

  test(
    'stale frames after disconnect do not reach domain event stream',
    () async {
      final channel = _TestChannel()..readyCompleter.complete();
      final source = WebSocketMessageEventSource(
        uri: Uri.parse('wss://example.test'),
        connector: (_) => channel,
      );
      final messages = <Object>[];
      final subscription = source.events().listen(messages.add);

      await source.connect();
      await source.disconnect();
      channel.incoming.add(
        '''{"roomId":1,"param":{"messageId":1,"sendUid":"u","sendTime":1700000000000,"type":0,"content":"stale"}}''',
      );
      await Future<void>.delayed(Duration.zero);

      expect(messages, isEmpty);
      await subscription.cancel();
    },
  );
}

class _TestChannel extends StreamChannelMixin<Object?>
    implements WebSocketChannel {
  final incoming = StreamController<Object?>();
  final outgoing = StreamController<Object?>();
  final readyCompleter = Completer<void>();
  late final WebSocketSink _sink = _TestSink(outgoing);

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  Future<void> get ready => readyCompleter.future;

  @override
  WebSocketSink get sink => _sink;

  @override
  Stream<Object?> get stream => incoming.stream;
}

class _TestSink implements WebSocketSink {
  _TestSink(this._incoming);

  final StreamController<Object?> _incoming;

  @override
  Future<void> get done => _incoming.done;

  @override
  void add(Object? data) => _incoming.sink.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _incoming.sink.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<Object?> stream) =>
      _incoming.sink.addStream(stream);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}
}
