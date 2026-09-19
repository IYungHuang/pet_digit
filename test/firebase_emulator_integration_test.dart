import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/chat/application/message_delta.dart';
import 'package:chat_pet_mvp/chat/data/firebase/firebase_media_upload_data_source.dart';
import 'package:chat_pet_mvp/chat/data/firebase/firebase_message_event_source.dart';
import 'package:chat_pet_mvp/chat/data/firebase/firebase_message_remote_data_source.dart';
import 'package:chat_pet_mvp/chat/data/firebase/firebase_message_repository.dart';
import 'package:chat_pet_mvp/chat/domain/message_content.dart';
import 'package:chat_pet_mvp/chat/domain/message_draft.dart';
import 'package:chat_pet_mvp/firebase/firebase_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final enabled = Platform.environment['FIREBASE_EMULATOR_TEST'] == '1';

  test(
    'Firebase emulator text and media flow',
    () async {
      if (!enabled) return;
      final environment = FirebaseEnvironment.localEmulator();
      await environment.initialize();
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final storage = FirebaseStorage.instance;
      final user = (await auth.signInAnonymously()).user!;
      const roomId = 'flutter-emulator-room';
      const clientId = 'flutter-text-client';
      final source = FirebaseMessageEventSource(
        firestore: firestore,
        auth: auth,
      );
      final repository = FirebaseMessageRepository(
        remote: FirebaseMessageRemoteDataSource(
          functions: functions,
          auth: auth,
        ),
        upload: FirebaseMediaUploadDataSource(storage: storage, auth: auth),
        events: source,
      );
      final tempFile = File(
        '${Directory.systemTemp.path}/flutter-emulator.png',
      );

      addTearDown(() async {
        await repository.dispose();
        await auth.signOut();
        if (await tempFile.exists()) await tempFile.delete();
      });

      await _seedMember(roomId: roomId, uid: user.uid);
      await source.setActiveRoom(roomId);
      await repository.connect();
      final events = <MessageDelta>[];
      final subscription = repository.watchDeltas().listen(events.add);
      addTearDown(subscription.cancel);

      final textDraft = MessageDraft(
        clientId: clientId,
        roomId: roomId,
        senderId: user.uid,
        content: const MessageContent.text(text: 'hello emulator'),
        createdAt: DateTime.now().toUtc(),
        isMine: true,
      );
      final first = await repository.send(textDraft);
      final retry = await repository.send(textDraft);
      expect(retry.serverId, first.serverId);
      await _waitFor(
        () => events.whereType<MessageAdded>().any(
          (event) => event.message.clientId == clientId,
        ),
      );
      expect(
        (await repository.loadMessages(
          roomId,
        )).where((message) => message.clientId == clientId),
        hasLength(1),
      );

      await tempFile.writeAsBytes([137, 80, 78, 71]);
      final mediaDraft = MessageDraft(
        clientId: 'flutter-image-client',
        roomId: roomId,
        senderId: user.uid,
        content: MessageContent.image(
          url: tempFile.path,
          localPath: tempFile.path,
          mimeType: 'image/png',
        ),
        createdAt: DateTime.now().toUtc(),
        isMine: true,
      );
      final mediaMessage = await repository.send(mediaDraft);
      expect(mediaMessage.serverId, isNotEmpty);
      expect(
        (await repository.loadMessages(
          roomId,
        )).where((message) => message.clientId == mediaDraft.clientId),
        hasLength(1),
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}

Future<void> _seedMember({required String roomId, required String uid}) async {
  await _putDocument('rooms/$roomId', {'roomId': _stringValue(roomId)});
  await _putDocument('rooms/$roomId/members/$uid', {
    'active': _boolValue(true),
  });
}

Future<void> _putDocument(String path, Map<String, dynamic> fields) async {
  final client = HttpClient();
  try {
    final request = await client.putUrl(
      Uri.parse(
        'http://127.0.0.1:8080/v1/projects/demo-pet-digit/databases/(default)/documents/$path',
      ),
    );
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer owner');
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'fields': fields}));
    final response = await request.close();
    if (response.statusCode >= 300) {
      throw StateError(
        'Firestore emulator seed failed: ${response.statusCode}',
      );
    }
  } finally {
    client.close(force: true);
  }
}

Map<String, dynamic> _stringValue(String value) => {'stringValue': value};
Map<String, dynamic> _boolValue(bool value) => {'booleanValue': value};

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  fail('Timed out waiting for Firebase delta');
}
