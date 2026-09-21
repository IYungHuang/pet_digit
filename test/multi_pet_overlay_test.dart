import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_pet_mvp/chat/domain/chat_models.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world_controller.dart';
import 'package:chat_pet_mvp/pet/presentation/pet_world_overlay.dart';
import 'package:chat_pet_mvp/pet/presentation/pixel_pet.dart';
import 'package:chat_pet_mvp/user/data/fake_user_pet_repository.dart';
import 'package:chat_pet_mvp/user/presentation/user_pet_providers.dart';
import 'package:chat_pet_mvp/chat/presentation/chat_shell.dart';

void main() {
  const testRoom = ChatRoom(
    id: 'test_room',
    name: 'Test Room',
    subtitle: 'Subtitle',
    messages: [],
  );

  group('Multi-Pet PetWorldOverlay Tests', () {
    testWidgets('renders single pet fallback when controllers is empty',
        (tester) async {
      final controller = PetWorldController(name: '阿福')
        ..selectedPet = PetType.corgi;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                PetWorldOverlay(room: testRoom, controller: controller),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(PixelPet), findsOneWidget);
      expect(find.text('阿福'), findsOneWidget);
    });

    testWidgets('renders multiple pets and their respective name badges',
        (tester) async {
      final c1 = PetWorldController(
        id: 'corgi_1',
        name: '阿福',
        spawnOffset: const Offset(20, 20),
      )..selectedPet = PetType.corgi;

      final c2 = PetWorldController(
        id: 'cat_1',
        name: '咪咪',
        spawnOffset: const Offset(100, 20),
      )..selectedPet = PetType.cat;

      final c3 = PetWorldController(
        id: 'parrot_1',
        name: '波波',
        spawnOffset: const Offset(180, 20),
      )..selectedPet = PetType.parrot;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                PetWorldOverlay(
                  room: testRoom,
                  controller: c1,
                  controllers: [c1, c2, c3],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      // Should find 3 PixelPet widgets
      expect(find.byType(PixelPet), findsNWidgets(3));

      // Should find all 3 name tags
      expect(find.text('阿福'), findsOneWidget);
      expect(find.text('咪咪'), findsOneWidget);
      expect(find.text('波波'), findsOneWidget);
    });

    testWidgets('ticks all controllers on each animation frame',
        (tester) async {
      final c1 = PetWorldController(name: 'P1');
      final c2 = PetWorldController(name: 'P2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                PetWorldOverlay(
                  room: testRoom,
                  controller: c1,
                  controllers: [c1, c2],
                ),
              ],
            ),
          ),
        ),
      );

      final initialPos1 = c1.position;
      final initialPos2 = c2.position;

      // Pump 1 second of frames
      await tester.pump(const Duration(seconds: 1));

      // Both controllers should have updated their internal state / time
      expect(c1.presentationState.position, equals(initialPos1));
      expect(c2.presentationState.position, equals(initialPos2));
    });
  });

  group('ChatShell Multi-Pet Room Integration Tests', () {
    testWidgets('ChatShell displays summoned pets in the active room',
        (tester) async {
      final fakeRepo = FakeUserPetRepository(currentUid: 'me');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPetRepositoryProvider.overrideWithValue(fakeRepo),
            fakeUserPetRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: ChatShell(),
          ),
        ),
      );
      await _pumpChat(tester);

      // In seeded fakeRepo 'friends' room:
      // 'me' has 阿福 (corgi)
      // 'user_friend_1' has 波波 (parrot)
      expect(find.byType(PixelPet), findsNWidgets(2));
      expect(find.text('阿福'), findsOneWidget);
      expect(find.text('波波'), findsOneWidget);

      // Now summon 咪咪 as well
      await fakeRepo.updateRoomPets(
        roomId: 'friends',
        petIds: ['pet_corgi_1', 'pet_cat_1'],
      );
      await _pumpChat(tester);

      // Now 3 pets should be in the room: 阿福, 咪咪, 波波
      expect(find.byType(PixelPet), findsNWidgets(3));
      expect(find.text('阿福'), findsOneWidget);
      expect(find.text('咪咪'), findsOneWidget);
      expect(find.text('波波'), findsOneWidget);

      fakeRepo.dispose();
    });
  });
}

Future<void> _pumpChat(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
