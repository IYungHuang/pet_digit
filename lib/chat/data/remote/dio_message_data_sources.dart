import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/message_content.dart';
import '../../domain/message_draft.dart';
import '../message_data_sources.dart';

/// Gespraech `message/add` adapter.
///
/// Backend sends media and message metadata in one multipart request. Therefore
/// [send] owns binary upload; [DioMediaUploadDataSource] only preserves the
/// existing fake-first repository seam.
class DioMessageRemoteDataSource implements MessageRemoteDataSource {
  DioMessageRemoteDataSource({
    required this.dio,
    this.endpoint = '/message/add',
  });

  final Dio dio;
  final String endpoint;

  @override
  Future<RemoteMessageReceipt> send(
    MessageDraft draft, {
    void Function(double progress)? onProgress,
  }) async {
    final form = await _formData(draft);
    final response = await dio.post<dynamic>(
      endpoint,
      data: form,
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call((sent / total).clamp(0.0, 1.0));
      },
    );
    final body = _map(response.data);
    final data = _map(body?['data']) ?? body;
    final serverId = data?['messageId'] ?? data?['id'];
    if (serverId == null) {
      throw StateError('message/add response missing messageId');
    }
    final timestamp = data?['sendTime'] ?? data?['createdAt'];
    return RemoteMessageReceipt(
      serverId: '$serverId',
      serverCreatedAt: _dateTime(timestamp),
    );
  }

  Future<FormData> _formData(MessageDraft draft) async {
    final common = <String, dynamic>{
      'tempUid': draft.clientId,
      'roomId': draft.roomId,
      'replyMessageId': null,
    };
    return draft.content.when(
      text: (text) => FormData.fromMap({...common, 'type': 0, 'content': text}),
      image: (url, mimeType, localPath) async => FormData.fromMap({
        ...common,
        'type': 2,
        'content': url,
        'image': await _file(localPath, url, mimeType),
      }),
      video: (url, mimeType, localPath, _, __) async => FormData.fromMap({
        ...common,
        'type': 6,
        'content': url,
        'video': await _file(localPath, url, mimeType),
      }),
    );
  }

  Future<MultipartFile> _file(
    String? localPath,
    String fallbackName,
    String mimeType,
  ) async {
    if (localPath == null || !await File(localPath).exists()) {
      throw StateError('media message requires localPath before upload');
    }
    return MultipartFile.fromFile(
      localPath,
      filename: fallbackName.split('/').last,
      contentType: DioMediaType.parse(mimeType),
    );
  }

  Map<String, dynamic>? _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  DateTime _dateTime(Object? value) {
    if (value == null) return DateTime.now().toUtc();
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toUtc();
    }
    throw FormatException('Invalid message timestamp: $value');
  }
}

/// Keeps repository upload stage explicit while backend upload remains atomic
/// inside [DioMessageRemoteDataSource.send].
class DioMediaUploadDataSource implements MediaUploadDataSource {
  @override
  bool get isAtomicUpload => true;

  @override
  Future<MessageContent> upload(
    MessageDraft draft, {
    void Function(double progress)? onProgress,
  }) async {
    return draft.content;
  }
}
