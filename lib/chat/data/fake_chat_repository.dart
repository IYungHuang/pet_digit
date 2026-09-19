import '../domain/chat_models.dart';

class FakeChatRepository {
  static final rooms = <ChatRoom>[
    const ChatRoom(
      id: 'friends',
      name: 'Pixel Pals',
      subtitle: '3 friends online',
      messages: [
        ChatMessage(
            id: 'f1',
            sender: 'Mina',
            text: 'Look who joined us!',
            kind: MessageKind.text,
            isMine: false),
        ChatMessage(
            id: 'f2',
            sender: 'You',
            text: '👋',
            kind: MessageKind.emoji,
            isMine: true),
        ChatMessage(
            id: 'f3',
            sender: 'Mina',
            text: 'Corgi dance.gif',
            kind: MessageKind.gif,
            isMine: false),
        ChatMessage(
            id: 'f4',
            sender: 'You',
            text: 'This chat has a tiny world.',
            kind: MessageKind.text,
            isMine: true),
      ],
    ),
    const ChatRoom(
      id: 'family',
      name: 'Family Nest',
      subtitle: 'Grandma and Dad',
      messages: [
        ChatMessage(
            id: 'a1',
            sender: 'Dad',
            text: 'Dinner at 7?',
            kind: MessageKind.text,
            isMine: false),
        ChatMessage(
            id: 'a2',
            sender: 'You',
            text: '🍜',
            kind: MessageKind.emoji,
            isMine: true),
        ChatMessage(
            id: 'a3',
            sender: 'Grandma',
            text: 'Cat video.gif',
            kind: MessageKind.gif,
            isMine: false),
      ],
    ),
  ];

  static ChatRoom roomById(String id) =>
      rooms.firstWhere((room) => room.id == id);
}
