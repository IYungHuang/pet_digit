import 'package:flutter/widgets.dart';

enum MessageKind { text, emoji, gif }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.kind,
    required this.isMine,
  });

  final String id;
  final String sender;
  final String text;
  final MessageKind kind;
  final bool isMine;
}

class ChatRoom {
  const ChatRoom(
      {required this.id,
      required this.name,
      required this.subtitle,
      required this.messages});

  final String id;
  final String name;
  final String subtitle;
  final List<ChatMessage> messages;
}

Offset messageWorldPosition(int index) =>
    Offset(26 + (index % 2) * 156, 92 + index * 76);
