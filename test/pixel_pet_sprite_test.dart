import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';
import 'package:chat_pet_mvp/pet/presentation/pixel_pet.dart';
import 'package:chat_pet_mvp/pet/presentation/pixel_pet_sprite.dart';

void main() {
  group('PixelPetSprite domain & assets', () {
    test('corgiAssetFor maps all PetStates and frames properly', () {
      expect(corgiAssetFor(PetState.idle, 0), 'assets/pets/corgi_idle_0.png');
      expect(corgiAssetFor(PetState.idle, 3), 'assets/pets/corgi_idle_3.png');
      expect(corgiAssetFor(PetState.idle, 4), 'assets/pets/corgi_idle_0.png');

      expect(corgiAssetFor(PetState.walk, 0), 'assets/pets/corgi_walk_0.png');
      expect(corgiAssetFor(PetState.walk, 2), 'assets/pets/corgi_walk_2.png');
      expect(corgiAssetFor(PetState.walk, 5), 'assets/pets/corgi_walk_1.png');

      expect(corgiAssetFor(PetState.run, 0), 'assets/pets/corgi_run_0.png');
      expect(corgiAssetFor(PetState.jump, 0), 'assets/pets/corgi_jump_0.png');
      expect(corgiAssetFor(PetState.pounce, 1), 'assets/pets/corgi_jump_1.png');
      expect(corgiAssetFor(PetState.observe, 0), 'assets/pets/corgi_observe_0.png');
    });

    test('petAssetFor maps cat and parrot PetStates and frames properly', () {
      expect(petAssetFor(PetType.corgi, PetState.idle, 0), 'assets/pets/corgi_idle_0.png');
      expect(petAssetFor(PetType.cat, PetState.idle, 1), 'assets/pets/cat_idle_1.png');
      expect(petAssetFor(PetType.cat, PetState.walk, 2), 'assets/pets/cat_walk_2.png');
      expect(petAssetFor(PetType.cat, PetState.run, 0), 'assets/pets/cat_run_0.png');
      expect(petAssetFor(PetType.cat, PetState.jump, 1), 'assets/pets/cat_jump_1.png');
      expect(petAssetFor(PetType.cat, PetState.observe, 0), 'assets/pets/cat_observe_0.png');

      expect(petAssetFor(PetType.parrot, PetState.idle, 2), 'assets/pets/parrot_idle_2.png');
      expect(petAssetFor(PetType.parrot, PetState.walk, 1), 'assets/pets/parrot_walk_1.png');
      expect(petAssetFor(PetType.parrot, PetState.run, 1), 'assets/pets/parrot_run_1.png');
      expect(petAssetFor(PetType.parrot, PetState.jump, 0), 'assets/pets/parrot_jump_0.png');
      expect(petAssetFor(PetType.parrot, PetState.observe, 1), 'assets/pets/parrot_observe_1.png');
    });

    test('PetConfig provides correct details and trail assets', () {
      final corgiConfig = PetConfig.of(PetType.corgi);
      expect(corgiConfig.avatarEmoji, '🐕');
      expect(corgiConfig.trailAsset, 'assets/pets/corgi_paw.png');
      expect(corgiConfig.isBird, false);

      final catConfig = PetConfig.of(PetType.cat);
      expect(catConfig.avatarEmoji, '🐱');
      expect(catConfig.trailAsset, 'assets/pets/cat_paw.png');
      expect(catConfig.voiceGreeting, '喵～');
      expect(catConfig.isBird, false);

      final parrotConfig = PetConfig.of(PetType.parrot);
      expect(parrotConfig.avatarEmoji, '🦜');
      expect(parrotConfig.trailAsset, 'assets/pets/parrot_paw.png');
      expect(parrotConfig.voiceGreeting, '好耶！');
      expect(parrotConfig.isBird, true);
    });

    test('CorgiSpriteSheet returns valid frame Rects', () {
      final idleRect = CorgiSpriteSheet.getFrameRect(PetState.idle, 1);
      expect(idleRect, const Rect.fromLTWH(128, 0, 128, 128));

      final walkRect = CorgiSpriteSheet.getFrameRect(PetState.walk, 2);
      expect(walkRect, const Rect.fromLTWH(256, 128, 128, 128));

      final runRect = CorgiSpriteSheet.getFrameRect(PetState.run, 0);
      expect(runRect, const Rect.fromLTWH(0, 256, 128, 128));

      final jumpRect = CorgiSpriteSheet.getFrameRect(PetState.jump, 1);
      expect(jumpRect, const Rect.fromLTWH(256, 384, 128, 128));

      final observeRect = CorgiSpriteSheet.getFrameRect(PetState.observe, 0);
      expect(observeRect, const Rect.fromLTWH(0, 512, 128, 128));
    });

    testWidgets('PixelPet renders without error across states and pet types', (tester) async {
      await tester.pumpWidget(const PixelPet(
        petType: PetType.corgi,
        state: PetState.idle,
        direction: 1.0,
        frameIndex: 0,
      ));
      expect(find.byType(PixelPet), findsOneWidget);

      await tester.pumpWidget(const PixelPet(
        petType: PetType.cat,
        state: PetState.walk,
        direction: -1.0,
        frameIndex: 1,
      ));
      expect(find.byType(PixelPet), findsOneWidget);

      await tester.pumpWidget(const PixelPet(
        petType: PetType.parrot,
        state: PetState.jump,
        direction: 1.0,
        frameIndex: 0,
      ));
      expect(find.byType(PixelPet), findsOneWidget);
    });
  });
}
