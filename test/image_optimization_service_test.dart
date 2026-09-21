import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:chat_pet_mvp/common/services/image_optimization_service.dart';

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker({this.xFileToReturn});

  XFile? xFileToReturn;
  bool throwUnsupported = false;
  double? lastMaxWidth;
  double? lastMaxHeight;
  int? lastQuality;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    if (throwUnsupported) {
      throw UnsupportedError('camera not supported');
    }
    lastMaxWidth = maxWidth;
    lastMaxHeight = maxHeight;
    lastQuality = imageQuality;
    return xFileToReturn;
  }
}

void main() {
  group('ImageOptimizationService', () {
    test('returns null when user cancels image picker', () async {
      final fakePicker = _FakeImagePicker(xFileToReturn: null);
      final service = ImageOptimizationService(picker: fakePicker);

      final result = await service.pickOptimizedImage();
      expect(result, isNull);
    });

    test('applies avatar preset constraints by default', () async {
      final fakePicker = _FakeImagePicker(
        xFileToReturn: XFile('/data/pet_dog.jpg', mimeType: 'image/jpeg'),
      );
      final service = ImageOptimizationService(picker: fakePicker);

      final result = await service.pickOptimizedImage(
        preset: ImageOptimizationPreset.avatar,
      );
      expect(result, isNotNull);
      expect(result!.path, '/data/pet_dog.jpg');
      expect(fakePicker.lastMaxWidth, 512.0);
      expect(fakePicker.lastMaxHeight, 512.0);
      expect(fakePicker.lastQuality, 85);
    });

    test('applies galleryPhoto preset constraints', () async {
      final fakePicker = _FakeImagePicker(
        xFileToReturn: XFile('/data/pet_album.png', mimeType: 'image/png'),
      );
      final service = ImageOptimizationService(picker: fakePicker);

      final result = await service.pickOptimizedImage(
        preset: ImageOptimizationPreset.galleryPhoto,
      );
      expect(result, isNotNull);
      expect(result!.path, '/data/pet_album.png');
      expect(fakePicker.lastMaxWidth, 1440.0);
      expect(fakePicker.lastMaxHeight, 1440.0);
      expect(fakePicker.lastQuality, 82);
    });

    test('rejects unsupported file formats', () async {
      final fakePicker = _FakeImagePicker(
        xFileToReturn: XFile('/data/document.pdf', mimeType: 'application/pdf'),
      );
      final service = ImageOptimizationService(picker: fakePicker);

      expect(
        () => service.pickOptimizedImage(),
        throwsA(isA<ImageOptimizationException>()),
      );
    });

    test('converts unsupported device errors to user-friendly exception', () async {
      final fakePicker = _FakeImagePicker()..throwUnsupported = true;
      final service = ImageOptimizationService(picker: fakePicker);

      expect(
        () => service.pickOptimizedImage(source: ImageSource.camera),
        throwsA(
          isA<ImageOptimizationException>().having(
            (e) => e.message,
            'message',
            contains('當前裝置不支援'),
          ),
        ),
      );
    });

    testWidgets('calculateCacheDimension scales by device pixel ratio and clamps', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final dim1 = ImageOptimizationService.calculateCacheDimension(
                context,
                48,
              );
              final dim2 = ImageOptimizationService.calculateCacheDimension(
                context,
                2000,
              );
              expect(dim1, greaterThanOrEqualTo(64));
              expect(dim2, lessThanOrEqualTo(1024));
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
