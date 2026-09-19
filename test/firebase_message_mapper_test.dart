import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/chat/application/message_delta.dart';
import 'package:chat_pet_mvp/chat/data/firebase/firebase_message_mapper.dart';
import 'package:chat_pet_mvp/chat/domain/message_content.dart';

void main() {
  test('maps canonical text document into added delta', () {
    final delta = FirebaseMessageMapper.fromDocumentMap(
      changeType: FirebaseDocumentChangeType.added,
      documentId: 'message-1',
      data: {
        'roomId': 'room-integration',
        'clientId': 'client-1',
        'senderId': 'user-integration',
        'kind': 'text',
        'text': 'hello',
        'state': 'normal',
        'createdAt': DateTime.utc(2026, 9, 19, 4),
        'updatedAt': DateTime.utc(2026, 9, 19, 4),
        'schemaVersion': 1,
      },
      currentUid: 'user-integration',
    );

    expect(delta, isA<MessageAdded>());
    final added = delta as MessageAdded;
    expect(added.origin, MessageAddedOrigin.live);
    final message = added.message;
    expect(message.serverId, 'message-1');
    expect(message.clientId, 'client-1');
    expect(message.content, const MessageContent.text(text: 'hello'));
    expect(message.isMine, isTrue);
  });

  test('marks first Firestore snapshot additions as history', () {
    final delta = FirebaseMessageMapper.fromDocumentMap(
      changeType: FirebaseDocumentChangeType.added,
      documentId: 'message-history',
      data: {..._imageData(), 'kind': 'text', 'text': 'history'},
      currentUid: 'other-user',
      addedOrigin: MessageAddedOrigin.initialSnapshot,
    );

    expect((delta as MessageAdded).origin, MessageAddedOrigin.initialSnapshot);
  });

  test('maps modified and removed changes without exposing Firestore DTOs', () {
    final modified = FirebaseMessageMapper.fromDocumentMap(
      changeType: FirebaseDocumentChangeType.modified,
      documentId: 'message-2',
      data: _imageData(),
      currentUid: 'other-user',
    );
    final removed = FirebaseMessageMapper.fromDocumentMap(
      changeType: FirebaseDocumentChangeType.removed,
      documentId: 'message-2',
      data: _imageData(),
      currentUid: 'other-user',
    );

    expect(modified, isA<MessageModified>());
    expect(
      (modified as MessageModified).message.content,
      isA<ImageMessageContent>(),
    );
    expect(removed, isA<MessageRemoved>());
    expect((removed as MessageRemoved).serverId, 'message-2');
    expect(removed, isNot(isA<Map>()));
  });
}

Map<String, dynamic> _imageData() => {
  'roomId': 'room-integration',
  'clientId': 'client-image',
  'senderId': 'other-user',
  'kind': 'image',
  'media': {
    'storagePath':
        'rooms/room-integration/media/other-user/client-image/original',
    'mimeType': 'image/png',
    'sizeBytes': 3,
  },
  'state': 'normal',
  'createdAt': DateTime.utc(2026, 9, 19, 4),
  'updatedAt': DateTime.utc(2026, 9, 19, 4),
  'schemaVersion': 1,
};
