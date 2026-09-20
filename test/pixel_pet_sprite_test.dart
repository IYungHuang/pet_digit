import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';
import 'package:chat_pet_mvp/pet/presentation/pixel_pet.dart';
import 'package:chat_pet_mvp/pet/presentation/pixel_pet_sprite.dart';

void main() {
  group('PixelPetSprite domain & assets', () {
    test('visible comparison ignores RGB stored under transparent pixels', () {
      final left = Uint8List.fromList([255, 0, 0, 0, 20, 30, 40, 255]);
      final right = Uint8List.fromList([0, 255, 0, 0, 20, 30, 40, 255]);

      expect(_visiblePixelsEqual(left, right), isTrue);
    });

    testWidgets('corgi walk frames are valid and visibly distinct', (
      tester,
    ) async {
      final visibleFrames = <Uint8List>[];

      for (var frame = 0; frame < 4; frame++) {
        final asset = await rootBundle.load(
          'assets/pets/corgi_walk_$frame.png',
        );
        final codec = (await tester.runAsync(
          () => ui.instantiateImageCodec(
            asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
          ),
        ))!;
        final decoded = (await tester.runAsync(codec.getNextFrame))!;
        final image = decoded.image;
        addTearDown(image.dispose);
        addTearDown(codec.dispose);

        expect(image.width, 128, reason: 'walk frame $frame width');
        expect(image.height, 128, reason: 'walk frame $frame height');

        final rgbaData = await tester.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
        );
        expect(rgbaData, isNotNull);
        final rgba = rgbaData!.buffer.asUint8List(
          rgbaData.offsetInBytes,
          rgbaData.lengthInBytes,
        );
        final alpha = <int>[
          for (var index = 3; index < rgba.length; index += 4) rgba[index],
        ];
        expect(alpha.any((value) => value == 0), isTrue);
        expect(alpha.any((value) => value > 0), isTrue);
        visibleFrames.add(Uint8List.fromList(rgba));
      }

      for (var left = 0; left < visibleFrames.length; left++) {
        for (var right = left + 1; right < visibleFrames.length; right++) {
          expect(
            _visiblePixelsEqual(visibleFrames[left], visibleFrames[right]),
            isFalse,
            reason: 'walk frames $left and $right must differ visibly',
          );
        }
      }
    });

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
      expect(
        corgiAssetFor(PetState.observe, 0),
        'assets/pets/corgi_observe_0.png',
      );
    });

    test('petAssetFor maps cat and parrot PetStates and frames properly', () {
      expect(
        petAssetFor(PetType.corgi, PetState.idle, 0),
        'assets/pets/corgi_idle_0.png',
      );
      expect(
        petAssetFor(PetType.cat, PetState.idle, 1),
        'assets/pets/cat_idle_1.png',
      );
      expect(
        petAssetFor(PetType.cat, PetState.walk, 2),
        'assets/pets/cat_walk_2.png',
      );
      expect(
        petAssetFor(PetType.cat, PetState.run, 0),
        'assets/pets/cat_run_0.png',
      );
      expect(
        petAssetFor(PetType.cat, PetState.jump, 1),
        'assets/pets/cat_jump_1.png',
      );
      expect(
        petAssetFor(PetType.cat, PetState.observe, 0),
        'assets/pets/cat_observe_0.png',
      );
      for (var frame = 0; frame < 6; frame++) {
        expect(
          petAssetFor(PetType.cat, PetState.pawTest, frame),
          'assets/pets/cat_paw_test_$frame.png',
        );
      }
      for (var frame = 0; frame < 4; frame++) {
        expect(
          petAssetFor(PetType.cat, PetState.catStalk, frame),
          'assets/pets/cat_stalk_$frame.png',
        );
      }
      for (var frame = 0; frame < 6; frame++) {
        expect(
          petAssetFor(PetType.corgi, PetState.dogProbe, frame),
          'assets/pets/corgi_novel_probe_$frame.png',
        );
        expect(
          petAssetFor(PetType.parrot, PetState.parrotProbe, frame),
          'assets/pets/parrot_novel_probe_$frame.png',
        );
      }

      expect(
        petAssetFor(PetType.parrot, PetState.idle, 2),
        'assets/pets/parrot_idle_2.png',
      );
      expect(
        petAssetFor(PetType.parrot, PetState.walk, 1),
        'assets/pets/parrot_walk_1.png',
      );
      expect(
        petAssetFor(PetType.parrot, PetState.run, 1),
        'assets/pets/parrot_run_1.png',
      );
      expect(
        petAssetFor(PetType.parrot, PetState.jump, 0),
        'assets/pets/parrot_jump_0.png',
      );
      expect(
        petAssetFor(PetType.parrot, PetState.observe, 1),
        'assets/pets/parrot_observe_1.png',
      );
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
      expect(idleRect, const ui.Rect.fromLTWH(128, 0, 128, 128));

      final walkRect = CorgiSpriteSheet.getFrameRect(PetState.walk, 2);
      expect(walkRect, const ui.Rect.fromLTWH(256, 128, 128, 128));

      final runRect = CorgiSpriteSheet.getFrameRect(PetState.run, 0);
      expect(runRect, const ui.Rect.fromLTWH(0, 256, 128, 128));

      final jumpRect = CorgiSpriteSheet.getFrameRect(PetState.jump, 1);
      expect(jumpRect, const ui.Rect.fromLTWH(256, 384, 128, 128));

      final observeRect = CorgiSpriteSheet.getFrameRect(PetState.observe, 0);
      expect(observeRect, const ui.Rect.fromLTWH(0, 512, 128, 128));
    });

    testWidgets('PixelPet renders without error across states and pet types', (
      tester,
    ) async {
      await tester.pumpWidget(
        const PixelPet(
          petType: PetType.corgi,
          state: PetState.idle,
          direction: 1.0,
          frameIndex: 0,
        ),
      );
      expect(find.byType(PixelPet), findsOneWidget);

      await tester.pumpWidget(
        const PixelPet(
          petType: PetType.cat,
          state: PetState.walk,
          direction: -1.0,
          frameIndex: 1,
        ),
      );
      expect(find.byType(PixelPet), findsOneWidget);

      await tester.pumpWidget(
        const PixelPet(
          petType: PetType.parrot,
          state: PetState.jump,
          direction: 1.0,
          frameIndex: 0,
        ),
      );
      expect(find.byType(PixelPet), findsOneWidget);

      for (var frame = 0; frame < 6; frame++) {
        await tester.pumpWidget(
          PixelPet(
            petType: PetType.cat,
            state: PetState.pawTest,
            direction: 1.0,
            frameIndex: frame,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }

      for (final (petType, state, frames) in [
        (PetType.cat, PetState.catStalk, 4),
        (PetType.corgi, PetState.dogProbe, 6),
        (PetType.parrot, PetState.parrotProbe, 6),
      ]) {
        for (var frame = 0; frame < frames; frame++) {
          await tester.pumpWidget(
            PixelPet(
              petType: petType,
              state: state,
              direction: 1.0,
              frameIndex: frame,
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
      }
    });
  });
}

bool _visiblePixelsEqual(Uint8List left, Uint8List right) {
  if (left.length != right.length || left.length % 4 != 0) return false;

  for (var offset = 0; offset < left.length; offset += 4) {
    final leftAlpha = left[offset + 3];
    final rightAlpha = right[offset + 3];
    if (leftAlpha == 0 && rightAlpha == 0) continue;

    for (var channel = 0; channel < 4; channel++) {
      if (left[offset + channel] != right[offset + channel]) return false;
    }
  }
  return true;
}
