import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:chat_pet_mvp/chat/application/media_picker_service.dart';
import 'package:chat_pet_mvp/chat/domain/media_policy.dart';

class _FakeImagePickerPlatform extends ImagePicker {
  _FakeImagePickerPlatform({this.xFileToReturn});

  XFile? xFileToReturn;
  bool throwErrorOnPick = false;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    if (throwErrorOnPick) throw StateError('picker failed');
    return xFileToReturn;
  }

  @override
  Future<XFile?> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async {
    if (throwErrorOnPick) throw StateError('picker failed');
    return xFileToReturn;
  }
}

void main() {
  group('NativeMediaPickerService', () {
    test('returns null when user cancels image pick', () async {
      final fakePicker = _FakeImagePickerPlatform(xFileToReturn: null);
      final service = NativeMediaPickerService(picker: fakePicker);

      final result = await service.pickImage(source: MediaPickerSource.gallery);
      expect(result, isNull);
    });

    test('successfully picks valid png image', () async {
      final fakePicker = _FakeImagePickerPlatform(
        xFileToReturn: XFile('/data/test_image.png', mimeType: 'image/png'),
      );
      final service = NativeMediaPickerService(picker: fakePicker);

      final result = await service.pickImage(source: MediaPickerSource.gallery);
      expect(result, isNotNull);
      expect(result!.path, '/data/test_image.png');
      expect(result.mimeType, 'image/png');
      expect(result.kind, MediaKind.image);
      expect(result.name, 'test_image.png');
    });

    test('successfully picks valid mp4 video', () async {
      final fakePicker = _FakeImagePickerPlatform(
        xFileToReturn: XFile('/movies/clip.mp4', mimeType: 'video/mp4'),
      );
      final service = NativeMediaPickerService(picker: fakePicker);

      final result = await service.pickVideo(source: MediaPickerSource.gallery);
      expect(result, isNotNull);
      expect(result!.path, '/movies/clip.mp4');
      expect(result.mimeType, 'video/mp4');
      expect(result.kind, MediaKind.video);
      expect(result.name, 'clip.mp4');
    });

    test(
      'throws MediaValidationException when unsupported format is selected',
      () async {
        final fakePicker = _FakeImagePickerPlatform(
          xFileToReturn: XFile(
            '/docs/document.pdf',
            mimeType: 'application/pdf',
          ),
        );
        final service = NativeMediaPickerService(picker: fakePicker);

        expect(
          () => service.pickImage(source: MediaPickerSource.gallery),
          throwsA(isA<MediaValidationException>()),
        );
      },
    );
  });

  group('FakeMediaPickerService', () {
    test('returns programmed picked media', () async {
      final fakeService = FakeMediaPickerService();
      fakeService.nextPickedImage = const PickedMediaFile(
        path: '/mock/img.jpg',
        name: 'img.jpg',
        mimeType: 'image/jpeg',
        kind: MediaKind.image,
      );

      final result = await fakeService.pickImage();
      expect(result?.name, 'img.jpg');
      expect(fakeService.pickImageCount, 1);
    });

    test('throws programmed error', () async {
      final fakeService = FakeMediaPickerService();
      fakeService.nextError = const MediaValidationException('Unsupported');

      expect(
        () => fakeService.pickImage(),
        throwsA(isA<MediaValidationException>()),
      );
    });
  });
}
