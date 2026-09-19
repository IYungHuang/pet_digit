import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/app.dart';
import 'package:chat_pet_mvp/chat/application/media_picker_service.dart';
import 'package:chat_pet_mvp/chat/domain/media_policy.dart';
import 'package:chat_pet_mvp/chat/presentation/chat_providers.dart';
import 'package:chat_pet_mvp/chat/presentation/chat_shell.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';
import 'package:chat_pet_mvp/pet/presentation/pet_world_overlay.dart';

void main() {
  testWidgets('shows active room messages and switches rooms', (tester) async {
    await tester.pumpWidget(const ChatPetApp());
    await _pumpChat(tester);

    expect(find.text('Pixel Pals'), findsWidgets);
    expect(find.text('Corgi dance.gif'), findsOneWidget);

    await tester.tap(find.text('Family Nest'));
    await _pumpChat(tester);

    expect(find.text('Family Nest'), findsWidgets);
    expect(find.text('Dinner at 7?'), findsOneWidget);
  });

  testWidgets('tapping emoji and GIF messages drives pet reactions', (
    tester,
  ) async {
    await tester.pumpWidget(const ChatPetApp());
    await _pumpChat(tester);

    await tester.tap(find.text('👋'));
    await tester.pump();
    final overlay = tester.widget<PetWorldOverlay>(
      find.byType(PetWorldOverlay),
    );
    expect(overlay.controller.state, PetState.pounce);
    expect(find.text('pounce!'), findsOneWidget);

    await tester.tap(find.text('Corgi dance.gif'));
    await tester.pump();
    expect(overlay.controller.state, PetState.observe);
    expect(find.text('watching'), findsOneWidget);
  });

  testWidgets('switches between Corgi, Cat, and Parrot from AppBar capsule', (
    tester,
  ) async {
    await tester.pumpWidget(const ChatPetApp());
    await _pumpChat(tester);

    final overlay = tester.widget<PetWorldOverlay>(
      find.byType(PetWorldOverlay),
    );
    expect(overlay.controller.selectedPet, PetType.corgi);
    expect(find.text('🐕'), findsOneWidget);
    expect(find.text('汪！'), findsOneWidget);

    // Tap Cat button
    await tester.tap(find.text('🐱'));
    await tester.pump();
    expect(overlay.controller.selectedPet, PetType.cat);
    expect(find.text('喵～'), findsOneWidget);

    // Tap Parrot button
    await tester.tap(find.text('🦜'));
    await tester.pump();
    expect(overlay.controller.selectedPet, PetType.parrot);
    expect(find.text('好耶！'), findsOneWidget);
  });

  testWidgets('sends text through composer and renders optimistic message', (
    tester,
  ) async {
    await tester.pumpWidget(const ChatPetApp());
    await _pumpChat(tester);

    await tester.enterText(find.byType(TextField), 'Hello from UI');
    await tester.tap(find.byTooltip('發送'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
    await tester.pump();

    expect(find.text('Hello from UI'), findsOneWidget);
  });

  testWidgets('fake attachment flow renders image message', (tester) async {
    await tester.pumpWidget(const ChatPetApp());
    await _pumpChat(tester);

    await tester.tap(find.byTooltip('新增附件'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('圖片（fake）'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
    await tester.pump();

    expect(find.text('photo.jpg'), findsOneWidget);
  });

  testWidgets('picks image via media picker service and renders optimistic message', (
    tester,
  ) async {
    final fakePicker = FakeMediaPickerService();
    fakePicker.nextPickedImage = const PickedMediaFile(
      path: '/mock/nature_vacation.png',
      name: 'nature_vacation.png',
      mimeType: 'image/png',
      kind: MediaKind.image,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaPickerServiceProvider.overrideWithValue(fakePicker),
        ],
        child: const MaterialApp(home: ChatShell()),
      ),
    );
    await _pumpChat(tester);

    await tester.tap(find.byTooltip('新增附件'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('從相簿選擇圖片'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
    await tester.pump();

    expect(fakePicker.pickImageCount, 1);
    expect(find.text('nature_vacation.png'), findsOneWidget);

  });

  testWidgets(
    'shows SnackBar when media format validation fails and preserves composer text',
    (tester) async {
      final fakePicker = FakeMediaPickerService();
      fakePicker.nextError = const MediaValidationException(
        '不支援的檔案格式，僅支援 JPG, PNG, GIF, WebP 圖片與 MP4, MOV 影片',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mediaPickerServiceProvider.overrideWithValue(fakePicker),
          ],
          child: const MaterialApp(home: ChatShell()),
        ),
      );
      await _pumpChat(tester);

      await tester.enterText(find.byType(TextField), 'Draft before error');
      await tester.tap(find.byTooltip('新增附件'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('從相簿選擇圖片'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('不支援的檔案格式'), findsOneWidget);
      expect(find.text('Draft before error'), findsOneWidget);
    },
  );

  testWidgets('message timeline scrolls through long room history', (
    tester,
  ) async {
    await tester.pumpWidget(const ChatPetApp());
    await _pumpChat(tester);

    final scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, -420));
    await tester.pump();

    expect(find.text('I can see the pets reacting.'), findsWidgets);
  });

  testWidgets('tapping preview button on media card opens ImagePreviewDialog', (
    tester,
  ) async {
    await tester.pumpWidget(const ChatPetApp());
    await _pumpChat(tester);

    expect(find.byIcon(Icons.fullscreen_rounded), findsWidgets);
    await tester.tap(find.byIcon(Icons.fullscreen_rounded).first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Corgi dance.gif'), findsWidgets);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

}

Future<void> _pumpChat(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

