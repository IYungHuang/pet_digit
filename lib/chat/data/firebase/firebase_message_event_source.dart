import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../application/message_delta.dart';
import '../../domain/chat_message.dart';
import '../../domain/message_connection_state.dart';
import '../message_data_sources.dart';
import 'firebase_message_mapper.dart';

class FirebaseMessageEventSource implements MessageEventSource {
  FirebaseMessageEventSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StreamController<MessageDelta> _deltaController =
      StreamController<MessageDelta>.broadcast();
  final StreamController<MessageConnectionState> _stateController =
      StreamController<MessageConnectionState>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? _activeRoomId;
  bool _connected = false;
  final FirebaseInitialSnapshotGate _initialSnapshotGate =
      FirebaseInitialSnapshotGate();

  Future<void> setActiveRoom(String roomId) async {
    if (roomId.isEmpty) throw ArgumentError.value(roomId, 'roomId');
    if (_activeRoomId == roomId) return;
    _activeRoomId = roomId;
    if (_connected) {
      await disconnect();
      await connect();
    }
  }

  @override
  Stream<MessageDelta> deltas() => _deltaController.stream;

  @override
  Stream<ChatMessage> events() => deltas()
      .where((delta) => delta is MessageAdded)
      .map((delta) => (delta as MessageAdded).message);

  @override
  Stream<MessageConnectionState> connectionStates() => _stateController.stream;

  @override
  Future<void> connect() async {
    if (_connected) return;
    final roomId = _activeRoomId;
    if (roomId == null) {
      throw StateError('Firebase event source requires an active room');
    }
    if (_auth.currentUser == null) {
      throw StateError('Authentication required for Firebase message listener');
    }
    _stateController.add(MessageConnectionState.connecting);
    _initialSnapshotGate.reset();
    final query = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt')
        .limitToLast(50);
    _subscription = query.snapshots().listen(
      (snapshot) {
        _stateController.add(MessageConnectionState.connected);
        final addedOrigin = _initialSnapshotGate.originForSnapshot(
          isFromCache: snapshot.metadata.isFromCache,
        );
        for (final change in snapshot.docChanges) {
          _deltaController.add(
            FirebaseMessageMapper.fromDocumentChange(
              change,
              currentUid: _auth.currentUser?.uid,
              addedOrigin: addedOrigin,
            ),
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _stateController.add(MessageConnectionState.reconnecting);
        _deltaController.addError(error, stackTrace);
      },
    );
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    _connected = false;
    _stateController.add(MessageConnectionState.disconnected);
  }

  Future<void> dispose() async {
    await disconnect();
    await _deltaController.close();
    await _stateController.close();
  }
}

class FirebaseInitialSnapshotGate {
  bool _awaitingServerSnapshot = true;

  MessageAddedOrigin originForSnapshot({required bool isFromCache}) {
    final origin = _awaitingServerSnapshot
        ? MessageAddedOrigin.initialSnapshot
        : MessageAddedOrigin.live;
    if (!isFromCache) _awaitingServerSnapshot = false;
    return origin;
  }

  void reset() => _awaitingServerSnapshot = true;
}
