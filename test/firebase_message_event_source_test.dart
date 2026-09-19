import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/chat/application/message_delta.dart';
import 'package:chat_pet_mvp/chat/data/firebase/firebase_message_event_source.dart';

void main() {
  test('cache-empty then server history both stay initial', () {
    final gate = FirebaseInitialSnapshotGate();

    expect(
      gate.originForSnapshot(isFromCache: true),
      MessageAddedOrigin.initialSnapshot,
    );
    expect(
      gate.originForSnapshot(isFromCache: false),
      MessageAddedOrigin.initialSnapshot,
    );
    expect(gate.originForSnapshot(isFromCache: false), MessageAddedOrigin.live);
  });

  test('reconnect resets initial snapshot suppression', () {
    final gate = FirebaseInitialSnapshotGate();
    gate.originForSnapshot(isFromCache: false);
    expect(gate.originForSnapshot(isFromCache: false), MessageAddedOrigin.live);

    gate.reset();

    expect(
      gate.originForSnapshot(isFromCache: false),
      MessageAddedOrigin.initialSnapshot,
    );
  });
}
