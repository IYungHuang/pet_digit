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
    'VideoPlayerBoundaryDialog renders playback boundary info and simulated play toggle',
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

      expect(find.text('影片播放器邊界'), findsOneWidget);
      expect(find.text('clip.mp4'), findsWidgets);

      expect(find.text('video/mp4'), findsOneWidget);
      expect(find.textContaining('15 秒'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Toggle simulated play
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('影片播放器邊界'), findsNothing);
    },
  );
}
