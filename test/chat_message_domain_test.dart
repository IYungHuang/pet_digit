import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/chat/domain/chat_message.dart';
import 'package:chat_pet_mvp/chat/domain/media_policy.dart';
import 'package:chat_pet_mvp/chat/domain/message_content.dart';
import 'package:chat_pet_mvp/chat/domain/message_draft.dart';
import 'package:chat_pet_mvp/chat/domain/message_status.dart';

void main() {
  group('chat message domain', () {
    test('creates text draft and message with pending defaults', () {
      final createdAt = DateTime.utc(2026, 9, 19, 1, 2, 3);
      final draft = MessageDraft(
        clientId: 'client-1',
        roomId: 'room-1',
        senderId: 'user-1',
        content: const MessageContent.text(text: 'hello'),
        createdAt: createdAt,
        isMine: true,
      );

      final message = ChatMessage.fromDraft(draft);

      expect(message.clientId, 'client-1');
      expect(message.serverId, isNull);
      expect(message.content, const MessageContent.text(text: 'hello'));
      expect(message.status, MessageDeliveryStatus.pending);
      expect(message.uploadProgress, 0);
      expect(message.createdAt, createdAt);
      expect(message.isMine, isTrue);
    });

    test('round trips image and video content through JSON', () {
      const image = MessageContent.image(
        url: 'https://example.test/photo.gif',
        mimeType: 'image/gif',
        localPath: '/tmp/photo.gif',
      );
      const video = MessageContent.video(
        url: 'https://example.test/video.mov',
        mimeType: 'video/quicktime',
        localPath: '/tmp/video.mov',
        thumbnailUrl: 'https://example.test/video.jpg',
        durationMs: 1200,
      );

      expect(MessageContent.fromJson(image.toJson()), image);
      expect(MessageContent.fromJson(video.toJson()), video);
    });

    test('accepts supported image and video MIME types', () {
      expect(MediaPolicy.isSupportedMimeType('image/jpeg'), isTrue);
      expect(MediaPolicy.isSupportedMimeType('image/png'), isTrue);
      expect(MediaPolicy.isSupportedMimeType('image/gif'), isTrue);
      expect(MediaPolicy.isSupportedMimeType('image/webp'), isTrue);
      expect(MediaPolicy.isSupportedMimeType('video/mp4'), isTrue);
      expect(MediaPolicy.isSupportedMimeType('video/quicktime'), isTrue);
      expect(MediaPolicy.isSupportedMimeType('application/pdf'), isFalse);
    });

    test('maps supported extensions to image or video media kinds', () {
      expect(MediaPolicy.kindForExtension('photo.JPG'), MediaKind.image);
      expect(MediaPolicy.kindForExtension('.webp'), MediaKind.image);
      expect(MediaPolicy.kindForExtension('animation.gif'), MediaKind.image);
      expect(MediaPolicy.kindForExtension('clip.mp4'), MediaKind.video);
      expect(MediaPolicy.kindForExtension('clip.MOV'), MediaKind.video);
      expect(MediaPolicy.kindForExtension('document.pdf'), isNull);
    });

    test('resolves canonical MIME type from file path extension', () {
      expect(MediaPolicy.mimeTypeForPath('photo.jpg'), 'image/jpeg');
      expect(MediaPolicy.mimeTypeForPath('/path/to/picture.PNG'), 'image/png');
      expect(MediaPolicy.mimeTypeForPath('sticker.gif'), 'image/gif');
      expect(MediaPolicy.mimeTypeForPath('graphic.webp'), 'image/webp');
      expect(MediaPolicy.mimeTypeForPath('/movies/clip.mp4'), 'video/mp4');
      expect(MediaPolicy.mimeTypeForPath('recording.mov'), 'video/quicktime');
      expect(MediaPolicy.mimeTypeForPath('unknown.xyz'), isNull);
    });

    test('validates supported and unsupported media files', () {
      final validImage = MediaPolicy.validate(path: '/tmp/pic.png');
      expect(validImage.isValid, isTrue);
      expect(validImage.kind, MediaKind.image);
      expect(validImage.mimeType, 'image/png');
      expect(validImage.errorMessage, isNull);

      final validVideo = MediaPolicy.validate(
        path: '/tmp/video.mov',
        mimeType: 'video/quicktime',
      );
      expect(validVideo.isValid, isTrue);
      expect(validVideo.kind, MediaKind.video);
      expect(validVideo.mimeType, 'video/quicktime');

      final unsupportedMime = MediaPolicy.validate(
        path: '/tmp/file.pdf',
        mimeType: 'application/pdf',
      );
      expect(unsupportedMime.isValid, isFalse);
      expect(unsupportedMime.errorMessage, contains('僅支援 JPG, PNG, GIF, WebP'));

      final unsupportedExt = MediaPolicy.validate(path: '/tmp/song.mp3');
      expect(unsupportedExt.isValid, isFalse);
      expect(unsupportedExt.errorMessage, contains('僅支援 JPG, PNG, GIF, WebP'));
    });

    test('rejects media larger than default 50 MiB limit', () {
      final result = MediaPolicy.validate(
        path: '/tmp/large.mp4',
        sizeBytes: MediaPolicy.maxMediaSizeBytes + 1,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('50MB'));
    });

    test('accepts media at exact size limit', () {
      final result = MediaPolicy.validate(
        path: '/tmp/exact.png',
        sizeBytes: MediaPolicy.maxMediaSizeBytes,
      );

      expect(result.isValid, isTrue);
    });
  });
}
