import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:chat_pet_mvp/chat/data/remote/remote_message_mapper.dart';
import 'package:chat_pet_mvp/chat/data/remote/dio_message_data_sources.dart';
import 'package:chat_pet_mvp/chat/data/message_data_sources.dart';
import 'package:chat_pet_mvp/chat/data/fake/fake_message_event_source.dart';
import 'package:chat_pet_mvp/chat/data/fake/fake_message_repository.dart';
import 'package:chat_pet_mvp/chat/domain/message_content.dart';
import 'package:chat_pet_mvp/chat/domain/message_draft.dart';
import 'dart:io';
import 'dart:typed_data';

void main() {
  test(
    'maps Gespraech OnMessageReceivedData text payload to domain message',
    () {
      final message = RemoteMessageMapper.fromWebSocket({
        'roomId': 12,
        'param': {
          'messageId': 88,
          'sendUid': 'user-7',
          'sendTime': 1700000000000,
          'type': 0,
          'content': 'hello',
          'tempUid': 'tmp-88',
        },
      });

      expect(message, isNotNull);
      expect(message!.clientId, 'tmp-88');
      expect(message.serverId, '88');
      expect(message.roomId, '12');
      expect(message.senderId, 'user-7');
      expect(
        message.content.map(
          text: (value) => value.text,
          image: (_) => '',
          video: (_) => '',
        ),
        'hello',
      );
      expect(message.isMine, isFalse);
    },
  );

  test('maps image and video message types to media content', () {
    final image = RemoteMessageMapper.fromWebSocket({
      'roomId': 'room-a',
      'param': {
        'messageId': 1,
        'sendUid': 'u',
        'sendTime': 1700000000000,
        'type': 2,
        'content': 'https://cdn.test/a.png',
        'fileName': 'a.png',
      },
    });
    final video = RemoteMessageMapper.fromWebSocket({
      'roomId': 'room-a',
      'param': {
        'messageId': 2,
        'sendUid': 'u',
        'sendTime': 1700000000000,
        'type': 6,
        'content': 'https://cdn.test/a.mp4',
        'fileName': 'a.mp4',
      },
    });

    expect(image!.content, isA<ImageMessageContent>());
    expect(video!.content, isA<VideoMessageContent>());
  });

  test('ignores unsupported WS message type without throwing', () {
    expect(
      RemoteMessageMapper.fromWebSocket({
        'roomId': 12,
        'param': {'messageId': 1, 'type': 99},
      }),
      isNull,
    );
  });

  test('Dio remote adapter sends text contract and maps receipt', () async {
    final dio = Dio();
    RequestOptions? request;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              data: {
                'data': {'messageId': 42, 'sendTime': 1700000000000},
              },
            ),
          );
        },
      ),
    );

    final receipt = await DioMessageRemoteDataSource(dio: dio).send(
      MessageDraft(
        clientId: 'tmp-1',
        roomId: '12',
        senderId: 'u',
        content: const MessageContent.text(text: 'hello'),
        createdAt: DateTime.utc(2023),
      ),
    );

    expect(receipt.serverId, '42');
    expect(request?.path, '/message/add');
    expect(request?.data, isA<FormData>());
    expect(
      (request!.data as FormData).fields,
      anyElement((entry) => entry.key == 'type' && entry.value == '0'),
    );
  });

  test('Dio remote adapter builds multipart video request', () async {
    final file = File('${Directory.systemTemp.path}/chat-adapter-test.mp4');
    await file.writeAsBytes(Uint8List.fromList([0, 1, 2]));
    addTearDown(() => file.delete());

    final dio = Dio();
    RequestOptions? request;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response<dynamic>(requestOptions: options, data: {'messageId': 43}),
          );
        },
      ),
    );

    await DioMessageRemoteDataSource(dio: dio).send(
      MessageDraft(
        clientId: 'tmp-video',
        roomId: '12',
        senderId: 'u',
        content: MessageContent.video(
          url: 'chat-adapter-test.mp4',
          localPath: file.path,
          mimeType: 'video/mp4',
        ),
        createdAt: DateTime.utc(2023),
      ),
    );

    final form = request!.data as FormData;
    expect(
      form.fields,
      anyElement((entry) => entry.key == 'type' && entry.value == '6'),
    );
    expect(
      form.fields,
      anyElement(
        (entry) => entry.key == 'tempUid' && entry.value == 'tmp-video',
      ),
    );
    expect(
      form.fields,
      anyElement((entry) => entry.key == 'roomId' && entry.value == '12'),
    );
    expect(form.files.map((entry) => entry.key), contains('video'));
    final videoPart = form.files.firstWhere((entry) => entry.key == 'video');
    expect(videoPart.value.filename, 'chat-adapter-test.mp4');
    expect(videoPart.value.contentType.toString(), 'video/mp4');
  });

  test(
    'atomic media upload stage does not report premature completion',
    () async {
      final progress = <double>[];
      final draft = MessageDraft(
        clientId: 'tmp-image',
        roomId: '12',
        senderId: 'u',
        content: const MessageContent.image(
          url: 'photo.png',
          mimeType: 'image/png',
          localPath: '/tmp/photo.png',
        ),
        createdAt: DateTime.utc(2023),
      );

      await DioMediaUploadDataSource().upload(draft, onProgress: progress.add);

      expect(progress, isEmpty);
    },
  );

  test('repository forwards atomic remote progress monotonically', () async {
    final progress = <double>[];
    final repository = FakeMessageRepository(
      remote: _ProgressRemote(),
      upload: DioMediaUploadDataSource(),
      events: FakeMessageEventSource(),
    );
    addTearDown(repository.dispose);

    final message = await repository.send(
      MessageDraft(
        clientId: 'atomic-image',
        roomId: '12',
        senderId: 'u',
        content: const MessageContent.image(
          url: 'photo.png',
          mimeType: 'image/png',
          localPath: '/tmp/photo.png',
        ),
        createdAt: DateTime.utc(2023),
      ),
      onUploadProgress: progress.add,
    );

    expect(progress, [0.2, 0.7, 1.0]);
    expect(message.status.name, 'sent');
  });
}

class _ProgressRemote implements MessageRemoteDataSource {
  @override
  Future<RemoteMessageReceipt> send(
    MessageDraft draft, {
    void Function(double progress)? onProgress,
  }) async {
    for (final value in [0.2, 0.7, 1.0]) {
      onProgress?.call(value);
    }
    return RemoteMessageReceipt(
      serverId: 'server-atomic',
      serverCreatedAt: DateTime.utc(2023),
    );
  }
}
