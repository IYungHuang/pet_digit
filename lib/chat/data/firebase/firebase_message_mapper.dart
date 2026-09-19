import 'package:cloud_firestore/cloud_firestore.dart';

import '../../application/message_delta.dart';
import '../../domain/chat_message.dart';
import '../../domain/message_content.dart';
import '../../domain/message_status.dart';

enum FirebaseDocumentChangeType { added, modified, removed }

class FirebaseMessageMapper {
  const FirebaseMessageMapper._();

  static MessageDelta fromDocumentChange(
    DocumentChange<Map<String, dynamic>> change, {
    String? currentUid,
    MessageAddedOrigin addedOrigin = MessageAddedOrigin.live,
  }) {
    final type = switch (change.type) {
      DocumentChangeType.added => FirebaseDocumentChangeType.added,
      DocumentChangeType.modified => FirebaseDocumentChangeType.modified,
      DocumentChangeType.removed => FirebaseDocumentChangeType.removed,
    };
    return fromDocumentMap(
      changeType: type,
      documentId: change.doc.id,
      data: change.doc.data() ?? const {},
      currentUid: currentUid,
      addedOrigin: addedOrigin,
    );
  }

  static MessageDelta fromDocumentMap({
    required FirebaseDocumentChangeType changeType,
    required String documentId,
    required Map<String, dynamic> data,
    String? currentUid,
    MessageAddedOrigin addedOrigin = MessageAddedOrigin.live,
  }) {
    if (changeType == FirebaseDocumentChangeType.removed) {
      return MessageDelta.removed(
        roomId: _requiredString(data, 'roomId'),
        clientId: data['clientId'] as String?,
        serverId: documentId,
      );
    }

    final message = _message(documentId, data, currentUid: currentUid);
    return switch (changeType) {
      FirebaseDocumentChangeType.added => MessageDelta.added(
        message,
        origin: addedOrigin,
      ),
      FirebaseDocumentChangeType.modified => MessageDelta.modified(message),
      FirebaseDocumentChangeType.removed => throw StateError('unreachable'),
    };
  }

  static ChatMessage _message(
    String documentId,
    Map<String, dynamic> data, {
    String? currentUid,
  }) {
    final createdAt = _dateTime(data['createdAt']);
    final kind = _requiredString(data, 'kind');
    final content = switch (kind) {
      'text' => MessageContent.text(text: _requiredString(data, 'text')),
      'image' => _media(data, image: true),
      'video' => _media(data, image: false),
      _ => throw FormatException('Unsupported Firebase message kind: $kind'),
    };
    return ChatMessage(
      clientId: _requiredString(data, 'clientId'),
      serverId: documentId,
      roomId: _requiredString(data, 'roomId'),
      senderId: _requiredString(data, 'senderId'),
      content: content,
      status: MessageDeliveryStatus.sent,
      createdAt: createdAt,
      serverCreatedAt: createdAt,
      isMine: currentUid != null && currentUid == data['senderId'],
    );
  }

  static MessageContent _media(
    Map<String, dynamic> data, {
    required bool image,
  }) {
    final media = data['media'];
    if (media is! Map) {
      throw const FormatException('Media metadata is required');
    }
    final values = Map<String, dynamic>.from(media);
    final path = _requiredString(values, 'storagePath');
    final mimeType = _requiredString(values, 'mimeType');
    if (image) {
      return MessageContent.image(url: path, mimeType: mimeType);
    }
    return MessageContent.video(
      url: path,
      mimeType: mimeType,
      durationMs: values['durationMs'] as int?,
    );
  }

  static String _requiredString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing Firebase message field: $key');
    }
    return value;
  }

  static DateTime _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toUtc();
    }
    throw FormatException('Invalid Firebase message timestamp: $value');
  }
}
