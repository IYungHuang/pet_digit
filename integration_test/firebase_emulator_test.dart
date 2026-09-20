import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:chat_pet_mvp/chat/application/message_delta.dart';
import 'package:chat_pet_mvp/chat/data/firebase/firebase_media_upload_data_source.dart';
import 'package:chat_pet_mvp/chat/data/firebase/firebase_message_event_source.dart';
import 'package:chat_pet_mvp/chat/data/firebase/firebase_message_remote_data_source.dart';
import 'package:chat_pet_mvp/chat/data/firebase/firebase_message_repository.dart';
import 'package:chat_pet_mvp/chat/domain/message_content.dart';
import 'package:chat_pet_mvp/chat/domain/message_draft.dart';
import 'package:chat_pet_mvp/firebase/firebase_environment.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Firebase emulator text, delta dedupe, and media flow', (
    tester,
  ) async {
    final environment = FirebaseEnvironment.localEmulator();
    await environment.initialize();
    final auth = FirebaseAuth.instance;
    final user = (await auth.signInAnonymously()).user!;
    const roomId = 'flutter-device-room';
    final source = FirebaseMessageEventSource(
      firestore: FirebaseFirestore.instance,
      auth: auth,
    );
    final repository = FirebaseMessageRepository(
      remote: FirebaseMessageRemoteDataSource(
        functions: FirebaseFunctions.instanceFor(
          region: firebaseFunctionsRegion,
        ),
        auth: auth,
      ),
      upload: FirebaseMediaUploadDataSource(
        storage: FirebaseStorage.instance,
        auth: auth,
      ),
      events: source,
    );
    final file = File('${Directory.systemTemp.path}/firebase-device.png');
    addTearDown(() async {
      await repository.dispose();
      await auth.signOut();
      if (await file.exists()) await file.delete();
    });

    await _seedMember(roomId, user.uid);
    await source.setActiveRoom(roomId);
    await repository.connect();
    final deltas = <MessageDelta>[];
    final subscription = repository.watchDeltas().listen(deltas.add);
    addTearDown(subscription.cancel);

    final draft = MessageDraft(
      clientId: 'device-text-client',
      roomId: roomId,
      senderId: user.uid,
      content: const MessageContent.text(text: 'device hello'),
      createdAt: DateTime.now().toUtc(),
      isMine: true,
    );
    final first = await repository.send(draft);
    final retry = await repository.send(draft);
    expect(retry.serverId, first.serverId);
    await _waitFor(
      () => deltas.whereType<MessageAdded>().any(
        (delta) => delta.message.clientId == draft.clientId,
      ),
    );

    await file.writeAsBytes([137, 80, 78, 71]);
    final media = MessageDraft(
      clientId: 'device-image-client',
      roomId: roomId,
      senderId: user.uid,
      content: MessageContent.image(
        url: file.path,
        localPath: file.path,
        mimeType: 'image/png',
      ),
      createdAt: DateTime.now().toUtc(),
      isMine: true,
    );
    expect((await repository.send(media)).serverId, isNotEmpty);
  });
}

Future<void> _seedMember(String roomId, String uid) async {
  final client = HttpClient();
  try {
    for (final entry in {
      'rooms/$roomId': {
        'roomId': {'stringValue': roomId},
      },
      'rooms/$roomId/members/$uid': {
        'active': {'booleanValue': true},
      },
    }.entries) {
      final request = await client.putUrl(
        Uri.parse(
          'http://127.0.0.1:8080/v1/projects/demo-pet-digit/databases/(default)/documents/${entry.key}',
        ),
      );
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer owner')
        ..contentType = ContentType.json;
      request.write(jsonEncode({'fields': entry.value}));
      final response = await request.close();
      if (response.statusCode >= 300) {
        throw StateError(
          'Firestore emulator seed failed: ${response.statusCode}',
        );
      }
    }
  } finally {
    client.close(force: true);
  }
}

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  fail('Timed out waiting for Firebase delta');
}
