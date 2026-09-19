import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/chat/presentation/widgets/media_preview_dialog.dart';

void main() {
  testWidgets('ImagePreviewDialog renders image title and can be dismissed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const ImagePreviewDialog(
                  url: 'photo.jpg',
                  mimeType: 'image/jpeg',
                ),
              ),
              child: const Text('Open Image'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Image'));
    await tester.pumpAndSettle();

    expect(find.text('photo.jpg'), findsWidgets);
    expect(find.text('image/jpeg'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('photo.jpg'), findsNothing);
  });

  testWidgets(
    'VideoPlayerBoundaryDialog renders fallback for unavailable fake source',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const VideoPlayerBoundaryDialog(
                    url: 'clip.mp4',
                    mimeType: 'video/mp4',
                    durationMs: 15000,
                  ),
                ),
                child: const Text('Open Video'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Video'));
      await tester.pumpAndSettle();

      expect(find.text('影片播放器'), findsOneWidget);
      expect(find.textContaining('15 秒'), findsOneWidget);
      expect(find.text('影片來源尚未可播放'), findsOneWidget);
      expect(find.text('重新載入'), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('影片播放器'), findsNothing);
    },
  );

  testWidgets(
    'VideoPlayerBoundaryDialog shows loading state for remote source',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoPlayerBoundaryDialog(
              url: 'https://example.com/clip.mp4',
              mimeType: 'video/mp4',
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('影片準備中'), findsOneWidget);
    },
  );
}
