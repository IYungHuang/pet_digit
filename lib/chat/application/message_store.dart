import '../domain/chat_message.dart';
import 'message_delta.dart';

class MessageStore {
  final Map<String, ChatMessage> _messagesByClientId = {};
  final Map<String, String> _clientIdByServerId = {};

  void mergeInitial(Iterable<ChatMessage> messages) {
    for (final message in messages) {
      _upsert(message);
    }
  }

  void apply(MessageDelta delta) {
    switch (delta) {
      case MessageAdded(:final message):
      case MessageModified(:final message):
        _upsert(message);
      case MessageRemoved(:final clientId, :final serverId):
        final resolvedClientId =
            clientId ??
            (serverId == null ? null : _clientIdByServerId[serverId]);
        if (resolvedClientId != null) _remove(resolvedClientId);
    }
  }

  List<ChatMessage> messagesForRoom(String roomId) {
    final messages =
        _messagesByClientId.values
            .where((message) => message.roomId == roomId)
            .toList()
          ..sort(_compareMessages);
    return List.unmodifiable(messages);
  }

  ChatMessage? messageByClientId(String clientId) =>
      _messagesByClientId[clientId];

  void _upsert(ChatMessage message) {
    final existingClientId = _messagesByClientId.containsKey(message.clientId)
        ? message.clientId
        : message.serverId == null
        ? null
        : _clientIdByServerId[message.serverId!];
    final clientId = existingClientId ?? message.clientId;

    if (message.serverId != null) {
      final conflictingClientId = _clientIdByServerId[message.serverId!];
      if (conflictingClientId != null && conflictingClientId != clientId) {
        _remove(conflictingClientId);
      }
    }

    final normalized = clientId == message.clientId
        ? message
        : message.copyWith(clientId: clientId);
    final previous = _messagesByClientId[clientId];
    if (previous?.serverId != null &&
        previous!.serverId != normalized.serverId) {
      _clientIdByServerId.remove(previous.serverId);
    }

    _messagesByClientId[clientId] = normalized;
    if (normalized.serverId != null) {
      _clientIdByServerId[normalized.serverId!] = clientId;
    }
  }

  void _remove(String clientId) {
    final removed = _messagesByClientId.remove(clientId);
    if (removed?.serverId != null) {
      _clientIdByServerId.remove(removed!.serverId);
    }
  }

  int _compareMessages(ChatMessage left, ChatMessage right) {
    final byCreatedAt = left.createdAt.compareTo(right.createdAt);
    if (byCreatedAt != 0) return byCreatedAt;
    return left.clientId.compareTo(right.clientId);
  }
}
