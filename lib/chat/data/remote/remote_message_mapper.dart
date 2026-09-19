import '../../domain/chat_message.dart';
import '../../domain/message_content.dart';
import '../../domain/message_status.dart';

/// Maps Gespraech wire payloads into transport-independent chat models.
class RemoteMessageMapper {
  const RemoteMessageMapper._();

  static ChatMessage? fromWebSocket(Map<String, dynamic> envelope) {
    final rawRoomId = envelope['roomId'];
    final param = _asMap(envelope['param']);
    if (rawRoomId == null || param == null) return null;

    final messageId = param['messageId'];
    final senderId = param['sendUid'];
    final type = param['type'];
    if (messageId == null || senderId == null || type is! num) return null;

    final content = _content(type.toInt(), param);
    if (content == null) return null;

    final clientId = '${param['tempUid'] ?? messageId}';
    final sendTime = _dateTime(param['sendTime']);
    return ChatMessage(
      clientId: clientId,
      serverId: '$messageId',
      roomId: '$rawRoomId',
      senderId: '$senderId',
      content: content,
      status: MessageDeliveryStatus.sent,
      createdAt: sendTime,
      serverCreatedAt: sendTime,
    );
  }

  static MessageContent? _content(int type, Map<String, dynamic> param) {
    final url = param['content']?.toString();
    if (url == null || url.isEmpty) return null;
    final name = param['fileName']?.toString();
    final mimeType = _mimeType(name ?? url);
    return switch (type) {
      0 => MessageContent.text(text: url),
      2 || 7 => MessageContent.image(url: url, mimeType: mimeType),
      6 => MessageContent.video(
        url: url,
        mimeType: mimeType,
        durationMs: _int(param['videoMilliseconds']),
      ),
      _ => null,
    };
  }

  static Map<String, dynamic>? _asMap(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  static DateTime _dateTime(Object? value) {
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

  static int? _int(Object? value) => value is num ? value.toInt() : null;

  static String _mimeType(String path) {
    final extension = path.split('?').first.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      _ => 'application/octet-stream',
    };
  }
}
