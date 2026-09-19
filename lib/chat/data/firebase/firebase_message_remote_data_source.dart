import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/message_content.dart';
import '../../domain/message_draft.dart';
import '../message_data_sources.dart';

class FirebaseMessageRemoteDataSource implements MessageRemoteDataSource {
  FirebaseMessageRemoteDataSource({
    required FirebaseFunctions functions,
    required FirebaseAuth auth,
  }) : _functions = functions,
       _auth = auth;

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  @override
  Future<RemoteMessageReceipt> send(
    MessageDraft draft, {
    void Function(double progress)? onProgress,
  }) async {
    if (_auth.currentUser == null) {
      throw StateError('Authentication required for Firebase message send');
    }
    final callableName = switch (draft.content) {
      TextMessageContent() => 'createMessage',
      ImageMessageContent() || VideoMessageContent() => 'finalizeMediaMessage',
    };
    final data = switch (draft.content) {
      TextMessageContent value => {
        'roomId': draft.roomId,
        'clientId': draft.clientId,
        'kind': 'text',
        'text': value.text,
      },
      ImageMessageContent value => await _mediaData(draft, value, 'image'),
      VideoMessageContent value => await _mediaData(draft, value, 'video'),
    };
    onProgress?.call(1);
    try {
      final result = await _functions.httpsCallable(callableName).call(data);
      final response = _map(result.data);
      final messageId = response?['messageId'];
      if (messageId is! String || messageId.isEmpty) {
        throw StateError('Firebase response missing messageId');
      }
      return RemoteMessageReceipt(
        serverId: messageId,
        serverCreatedAt: DateTime.now().toUtc(),
      );
    } on FirebaseFunctionsException catch (error) {
      throw StateError(
        'Firebase ${error.code}: ${error.message ?? error.code}',
      );
    }
  }

  Future<Map<String, dynamic>> _mediaData(
    MessageDraft draft,
    MessageContent content,
    String kind,
  ) async {
    final path = switch (content) {
      ImageMessageContent value => value.url,
      VideoMessageContent value => value.url,
      TextMessageContent() => throw StateError('Text has no media path'),
    };
    final localPath = switch (content) {
      ImageMessageContent value => value.localPath,
      VideoMessageContent value => value.localPath,
      TextMessageContent() => null,
    };
    if (localPath == null) throw StateError('Media message requires localPath');
    final sizeBytes = await File(localPath).length();
    final mimeType = switch (content) {
      ImageMessageContent value => value.mimeType,
      VideoMessageContent value => value.mimeType,
      TextMessageContent() => throw StateError('Text has no MIME type'),
    };
    return {
      'roomId': draft.roomId,
      'clientId': draft.clientId,
      'kind': kind,
      'storagePath': path,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
    };
  }

  Map<String, dynamic>? _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;
}
