import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/message_content.dart';
import '../../domain/message_draft.dart';
import '../message_data_sources.dart';

class FirebaseMediaUploadDataSource implements MediaUploadDataSource {
  FirebaseMediaUploadDataSource({
    required FirebaseStorage storage,
    required FirebaseAuth auth,
  }) : _storage = storage,
       _auth = auth;

  static const maxBytes = 52_428_800;
  static const supportedMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'video/mp4',
    'video/quicktime',
  };

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  @override
  bool get isAtomicUpload => false;

  static bool isSupportedMime(String mimeType) =>
      supportedMimeTypes.contains(mimeType);

  static bool isValidStagingPath(
    String path, {
    required String roomId,
    required String uid,
    required String clientId,
  }) => path == 'rooms/$roomId/media/$uid/$clientId/original';

  @override
  Future<MessageContent> upload(
    MessageDraft draft, {
    void Function(double progress)? onProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Authentication required for media upload');
    }
    final content = draft.content;
    final localPath = switch (content) {
      ImageMessageContent value => value.localPath,
      VideoMessageContent value => value.localPath,
      TextMessageContent() => throw StateError('Text does not require upload'),
    };
    final mimeType = switch (content) {
      ImageMessageContent value => value.mimeType,
      VideoMessageContent value => value.mimeType,
      TextMessageContent() => throw StateError('Text does not have MIME type'),
    };
    if (localPath == null) {
      throw StateError('Media message requires localPath');
    }
    if (!isSupportedMime(mimeType)) {
      throw ArgumentError('Unsupported MIME type: $mimeType');
    }
    final file = File(localPath);
    if (!await file.exists()) {
      throw StateError('Media file does not exist: $localPath');
    }
    final sizeBytes = await file.length();
    if (sizeBytes > maxBytes) throw ArgumentError('Media exceeds 50 MiB limit');
    final path =
        'rooms/${draft.roomId}/media/${user.uid}/${draft.clientId}/original';
    final task = _storage
        .ref(path)
        .putFile(
          file,
          SettableMetadata(
            contentType: mimeType,
            customMetadata: {
              'uid': user.uid,
              'roomId': draft.roomId,
              'clientId': draft.clientId,
            },
          ),
        );
    task.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });
    await task;
    // Backend owns orphan cleanup; retry reuses same deterministic path.
    return switch (content) {
      ImageMessageContent value => value.copyWith(url: path),
      VideoMessageContent value => value.copyWith(url: path),
      TextMessageContent() => throw StateError('Text does not require upload'),
    };
  }
}
