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

    testWidgets(
        'showImageSourceActionSheet presents camera and gallery options and returns camera on tap',
        (tester) async {
      ImageSource? selectedSource;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedSource =
                    await ImageOptimizationService.showImageSourceActionSheet(
                  context,
                  title: '選擇生活照來源',
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('選擇生活照來源'), findsOneWidget);
      expect(find.text('拍照 (立即拍攝)'), findsOneWidget);
      expect(find.text('從相簿選取'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);

      await tester.tap(find.text('拍照 (立即拍攝)'));
      await tester.pumpAndSettle();

      expect(selectedSource, ImageSource.camera);
    });

    testWidgets(
      'showImageSourcePickerAndPick bypasses bottom sheet when isMobile is false (desktop/web)',
      (tester) async {
        final fakePicker = _FakeImagePicker(
          xFileToReturn: XFile('/data/desktop_photo.jpg', mimeType: 'image/jpeg'),
        );
        final service = ImageOptimizationService(picker: fakePicker);
        XFile? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await service.showImageSourcePickerAndPick(
                    context,
                    isMobileOverride: false,
                  );
                },
                child: const Text('Pick Image'),
              ),
            ),
          ),
        );

        await tester.runAsync(() async {
          await tester.tap(find.text('Pick Image'));
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();

        // Should NOT show the bottom sheet
        expect(find.text('拍照 (立即拍攝)'), findsNothing);
        expect(result, isNotNull);
        expect(result!.path, '/data/desktop_photo.jpg');
      },
    );

    testWidgets(
      'showImageSourcePickerAndPick shows bottom sheet when isMobile is true (iOS/Android)',
      (tester) async {
        final fakePicker = _FakeImagePicker(
          xFileToReturn: XFile('/data/mobile_photo.jpg', mimeType: 'image/jpeg'),
        );
        final service = ImageOptimizationService(picker: fakePicker);
        XFile? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await service.showImageSourcePickerAndPick(
                    context,
                    isMobileOverride: true,
                  );
                },
                child: const Text('Pick Image'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Pick Image'));
        await tester.pumpAndSettle();

        // Bottom sheet should be visible
        expect(find.text('拍照 (立即拍攝)'), findsOneWidget);
        expect(find.text('從相簿選取'), findsOneWidget);

        // Tap camera
        await tester.tap(find.text('拍照 (立即拍攝)'));
        await tester.pump();
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.path, '/data/mobile_photo.jpg');
      },
    );
  });
}
