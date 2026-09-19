import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/app.dart';
import 'package:chat_pet_mvp/chat/application/media_picker_service.dart';
import 'package:chat_pet_mvp/chat/data/fake/fake_media_upload_data_source.dart';
import 'package:chat_pet_mvp/chat/data/fake/fake_message_event_source.dart';
import 'package:chat_pet_mvp/chat/data/fake/fake_message_remote_data_source.dart';
import 'package:chat_pet_mvp/chat/data/fake/fake_message_repository.dart';
import 'package:chat_pet_mvp/chat/domain/chat_message.dart';
import 'package:chat_pet_mvp/chat/domain/media_policy.dart';
import 'package:chat_pet_mvp/chat/domain/message_content.dart';
import 'package:chat_pet_mvp/chat/domain/message_status.dart';
import 'package:chat_pet_mvp/chat/presentation/chat_providers.dart';
import 'package:chat_pet_mvp/chat/presentation/chat_shell.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world_controller.dart';
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

  testWidgets('tapping GIF moves pet beside its measured bubble', (
    tester,
  ) async {
    await tester.pumpWidget(const ChatPetApp());
    await _pumpChat(tester);

    await tester.tap(find.text('Corgi dance.gif'));
    await tester.pump(const Duration(milliseconds: 1900));

    final overlay = tester.widget<PetWorldOverlay>(
      find.byType(PetWorldOverlay),
    );
    final bounds = overlay.controller.activeTarget!.bounds;
    expect(
      overlay.controller.position,
      Offset(bounds.right + 8, bounds.bottom - 52),
    );
  });

  testWidgets('server-backed message card measures its canonical pet target', (
    tester,
  ) async {
    await tester.pumpWidget(const ChatPetApp());
    await _pumpChat(tester);

    final overlay = tester.widget<PetWorldOverlay>(
      find.byType(PetWorldOverlay),
    );
    final target =
        overlay.controller.objects.firstWhere(
              (object) => object.id == 'seed-f2',
            )
            as PetBoundedInteractable;

    expect(target.hasMeasuredBounds, isTrue);
    expect(target.bounds.width, greaterThan(0));
    expect(target.bounds.height, greaterThan(0));
  });

  testWidgets('server-backed bubble follows its canonical spring deflection', (
    tester,
  ) async {
    await tester.pumpWidget(const ChatPetApp());
    await _pumpChat(tester);

    final bubble = find.text('👋');
    final controller = tester
        .widget<PetWorldOverlay>(find.byType(PetWorldOverlay))
        .controller;

    controller.triggerBubbleImpulse('seed-f2', 180);
    await tester.pump(const Duration(milliseconds: 16));

    final deflection = controller.getBubbleDeflection('seed-f2');
    expect(deflection, greaterThan(0));
    expect(_bubbleTranslationY(tester, bubble), closeTo(deflection, 0.1));
  });

  testWidgets('acknowledged bubble keeps rendering its active spring', (
    tester,
  ) async {
    final events = FakeMessageEventSource();
    final repository = FakeMessageRepository(
      remote: FakeMessageRemoteDataSource(),
      upload: FakeMediaUploadDataSource(),
      events: events,
    );
    final pending = ChatMessage(
      clientId: 'pending-client',
      roomId: 'friends',
      senderId: 'You',
      content: const MessageContent.text(text: 'acknowledgement keeps bounce'),
      status: MessageDeliveryStatus.sending,
      createdAt: DateTime(2026, 9, 19),
      isMine: true,
    );
    repository.seedMessages([pending]);
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatEventSourceProvider.overrideWithValue(events),
          chatRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ChatShell()),
      ),
    );
    await _pumpChat(tester);

    final bubble = find.text('acknowledgement keeps bounce');
    final controller = tester
        .widget<PetWorldOverlay>(find.byType(PetWorldOverlay))
        .controller;
    controller.triggerBubbleImpulse('pending-client', 180);
    await tester.pump(const Duration(milliseconds: 16));

    events.emitModified(
      pending.copyWith(
        serverId: 'server-ack',
        status: MessageDeliveryStatus.sent,
      ),
    );
    await tester.pump();

    final deflection = controller.getBubbleDeflection('server-ack');
    expect(deflection, greaterThan(0));
    expect(controller.getBubbleDeflection('pending-client'), 0);
    expect(_bubbleTranslationY(tester, bubble), closeTo(deflection, 0.1));
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

  testWidgets('disables send for blank and whitespace-only drafts', (
    tester,
  ) async {
    await tester.pumpWidget(const ChatPetApp());
    await _pumpChat(tester);

    final sendButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.send_rounded),
        matching: find.byType(IconButton),
      ),
    );
    expect(sendButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byIcon(Icons.send_rounded),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byIcon(Icons.send_rounded),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('preserves draft when switching rooms', (tester) async {
    await tester.pumpWidget(const ChatPetApp());
    await _pumpChat(tester);

    await tester.enterText(find.byType(TextField), 'Friends draft');
    await tester.tap(find.text('Family Nest'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );

    await tester.tap(find.text('Pixel Pals'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Friends draft',
    );
  });

  testWidgets('hides demo attachment actions outside demo composition', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ChatShell())),
    );
    await _pumpChat(tester);

    await tester.tap(find.byTooltip('新增附件'));
    await tester.pump();
    expect(find.text('圖片（demo）'), findsNothing);
    expect(find.text('影片（demo）'), findsNothing);
  });

  testWidgets(
    'does not show transient disconnected banner during fake connect',
    (tester) async {
      await tester.pumpWidget(const ChatPetApp());
      await tester.pump();

      expect(find.text('尚未連線'), findsNothing);
    },
  );

  testWidgets('fake attachment flow renders image message', (tester) async {
    await tester.pumpWidget(const ChatPetApp());
    await _pumpChat(tester);

    await tester.tap(find.byTooltip('新增附件'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('圖片（demo）'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 16));
    final overlay = tester.widget<PetWorldOverlay>(
      find.byType(PetWorldOverlay),
    );
    expect(overlay.controller.currentAction, PetActionType.dogProbe);

    final card = find.bySemanticsLabel(RegExp(r'^You：圖片訊息'));
    final cardRect = tester.getRect(card);
    final overlayOrigin = tester.getTopLeft(find.byType(PetWorldOverlay));
    final measuredBounds = overlay.controller.activeTarget!.bounds;
    final timeline = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(ListView).last,
        matching: find.byType(Scrollable),
      ),
    );
    expect(timeline.position.pixels, greaterThan(0));
    expect(measuredBounds.left, closeTo(cardRect.left - overlayOrigin.dx, 1));
    expect(measuredBounds.top, closeTo(cardRect.top - overlayOrigin.dy, 1));

    await tester.pump(const Duration(milliseconds: 1200));
    final liveBounds = overlay.controller.activeTarget!.bounds;
    expect(
      overlay.controller.position,
      Offset(liveBounds.left - 72, liveBounds.bottom - 52),
    );

    expect(find.text('photo.jpg'), findsOneWidget);
  });

  testWidgets(
    'picks image via media picker service and renders optimistic message',
    (tester) async {
      final fakePicker = FakeMediaPickerService();
      fakePicker.nextPickedImage = const PickedMediaFile(
        path: '/mock/nature_vacation.png',
        name: 'nature_vacation.png',
        mimeType: 'image/png',
        kind: MediaKind.image,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [mediaPickerServiceProvider.overrideWithValue(fakePicker)],
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
    },
  );

  testWidgets(
    'shows SnackBar when media format validation fails and preserves composer text',
    (tester) async {
      final fakePicker = FakeMediaPickerService();
      fakePicker.nextError = const MediaValidationException(
        '不支援的檔案格式，僅支援 JPG, PNG, GIF, WebP 圖片與 MP4, MOV 影片',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [mediaPickerServiceProvider.overrideWithValue(fakePicker)],
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

    final scrollable = find.byType(ListView).last;
    await tester.drag(scrollable, const Offset(0, -420));
    await tester.pump();

    expect(find.text('I can see the pets reacting.'), findsWidgets);
  });

  testWidgets('timeline keeps messages aligned to the top of viewport', (
    tester,
  ) async {
    await tester.pumpWidget(const ChatPetApp());
    await _pumpChat(tester);

    final top = tester.getTopLeft(find.text('Look who joined us!')).dy;
    expect(top, lessThan(220));
  });

  testWidgets('newly sent message is brought into the lower timeline area', (
    tester,
  ) async {
    await tester.pumpWidget(const ChatPetApp());
    await _pumpChat(tester);

    await tester.enterText(find.byType(TextField), 'bottom placement check');
    await tester.tap(find.byTooltip('發送'));
    await tester.pump(const Duration(milliseconds: 500));

    final message = find.text('bottom placement check');
    expect(message, findsOneWidget);
    expect(tester.getBottomRight(message).dy, greaterThan(420));
  });

  testWidgets('short room history is bottom-aligned above composer', (
    tester,
  ) async {
    await tester.pumpWidget(const ChatPetApp());
    await _pumpChat(tester);
    await tester.tap(find.text('Family Nest'));
    await _pumpChat(tester);

    final lastBottom = tester.getBottomRight(find.text('Cat video.gif')).dy;
    final composerTop = tester.getTopLeft(find.byType(TextField)).dy;
    expect(lastBottom, greaterThan(400));
    expect(composerTop - lastBottom, lessThan(100));
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

double _bubbleTranslationY(WidgetTester tester, Finder bubble) {
  final transform = find
      .ancestor(of: bubble, matching: find.byType(Transform))
      .evaluate()
      .map((element) => element.widget as Transform)
      .firstWhere((transform) => transform.alignment == null);
  return transform.transform.storage[13];
}
