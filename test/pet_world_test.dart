import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:chat_pet_mvp/chat/data/fake_chat_repository.dart';
import 'package:chat_pet_mvp/pet/domain/pet_effects.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world_controller.dart';

void main() {
  test('loads message bubbles as platforms and reacts to emoji and GIF', () {
    final controller = PetWorldController();
    final room = FakeChatRepository.rooms.first;

    controller.loadRoom(room);
    _measureTargets(controller);

    expect(controller.objects, isNotEmpty);
    expect(
      controller.objects.any(
        (object) => object.kind == WorldObjectKind.platform,
      ),
      isTrue,
    );

    final emoji = controller.objects.firstWhere(
      (object) => object.kind == WorldObjectKind.emojiToy,
    );
    controller.interact(emoji.id);
    expect(controller.state, PetState.pounce);

    final gif = controller.objects.firstWhere(
      (object) => object.kind == WorldObjectKind.animatedToy,
    );
    controller.interact(gif.id);
    expect(controller.state, PetState.observe);
  });

  test('loading another room resets pet location and state', () {
    final controller = PetWorldController();
    controller.loadRoom(FakeChatRepository.rooms.first);
    _measureTargets(controller);
    controller.interact(controller.objects.first.id);
    controller.loadRoom(FakeChatRepository.rooms.last);

    expect(controller.state, PetState.idle);
    expect(controller.position.dx, 24);
  });

  test('walking advances pet position instead of only changing pose', () {
    final controller = PetWorldController();
    controller.loadRoom(FakeChatRepository.rooms.first);

    controller.tick(const Duration(seconds: 2));
    final start = controller.position.dx;
    controller.tick(const Duration(milliseconds: 500));

    expect(controller.state, PetState.walk);
    expect(controller.position.dx, greaterThan(start));
  });

  test('controller updates direction and frameIndex during movement', () {
    final controller = PetWorldController();
    expect(controller.direction, 1.0);
    expect(controller.frameIndex, 0);

    // Idle frame progression
    controller.tick(const Duration(milliseconds: 300));
    expect(controller.frameIndex, 1);

    // Transition to walk
    controller.tick(const Duration(milliseconds: 1300));
    expect(controller.state, PetState.walk);
    expect(controller.frameIndex, 0);

    // Walk frame progression
    controller.tick(const Duration(milliseconds: 200));
    expect(controller.frameIndex, 1);
  });

  test(
    'interacts with text platform bubble via jump arc and stands on top',
    () {
      final controller = PetWorldController();
      controller.loadRoom(FakeChatRepository.rooms.first);
      _measureTargets(controller);

      final textPlatform = controller.objects.firstWhere(
        (object) => object.kind == WorldObjectKind.platform,
      );
      controller.interact(textPlatform.id);

      expect(controller.state, PetState.jump);
      expect(controller.currentAction, PetActionType.jumpToPlatform);

      // Complete jump trajectory
      controller.tick(const Duration(milliseconds: 600));
      expect(controller.currentPlatform, isNotNull);
      expect(controller.position.dy, textPlatform.bounds.top - 52);
      expect(controller.particles, isNotEmpty); // Landing dust puffs
    },
  );

  test(
    'tapping emoji launches bouncing toy and corgi chases with dust trails',
    () {
      final controller = PetWorldController();
      controller.loadRoom(FakeChatRepository.rooms.first);
      _measureTargets(controller);

      final emojiToy = controller.objects.firstWhere(
        (object) => object.kind == WorldObjectKind.emojiToy,
      );
      controller.interact(emojiToy.id);

      expect(controller.state, PetState.pounce);
      expect(controller.bouncingToy, isNotNull);
      expect(controller.currentAction, PetActionType.chaseEmoji);

      // Tick to advance chase and spawn dust
      controller.tick(const Duration(milliseconds: 200));
      expect(controller.bouncingToy, isNotNull);
      expect(controller.particles, isNotEmpty);
    },
  );

  test('dog tap preserves legacy GIF inspection', () {
    final controller = PetWorldController();
    controller.loadRoom(FakeChatRepository.rooms.first);
    _measureTargets(controller);

    final gifToy = controller.objects.firstWhere(
      (object) => object.kind == WorldObjectKind.animatedToy,
    );
    gifToy.markMeasuredBounds(const Rect.fromLTWH(18, 180, 180, 52));
    controller.interact(gifToy.id);

    expect(controller.state, PetState.observe);
    expect(controller.currentAction, PetActionType.inspectGif);
    final start = controller.position;

    controller.tick(const Duration(milliseconds: 800));
    expect(controller.position, start);

    controller.tick(const Duration(milliseconds: 500));
    expect(controller.position, isNot(start));

    controller.tick(const Duration(milliseconds: 600));
    expect(controller.position, const Offset(206, 180));

    controller.tick(const Duration(milliseconds: 1000));
    expect(controller.currentAction, PetActionType.none);

    controller.tick(const Duration(milliseconds: 1000));
    expect(controller.currentAction, PetActionType.none);
  });

  test(
    'landing on bubble triggers spring oscillation and dog bounces synchronously',
    () {
      final controller = PetWorldController();
      controller.loadRoom(FakeChatRepository.rooms.first);
      _measureTargets(controller);

      final platform = controller.objects.firstWhere(
        (object) => object.kind == WorldObjectKind.platform,
      );
      controller.interact(platform.id);

      // Complete jump trajectory to impact landing
      controller.tick(const Duration(milliseconds: 550));

      // Next tick integrates impact velocity into downward deflection
      controller.tick(const Duration(milliseconds: 40));
      final initialDeflection = controller.getBubbleDeflection(platform.id);
      expect(initialDeflection, greaterThan(0));

      // Dog Y position is precisely shifted down by the bubble's spring deflection
      final expectedBaseY = platform.bounds.top - 52;
      expect(
        controller.position.dy,
        closeTo(expectedBaseY + initialDeflection, 0.001),
      );

      // Progress time to observe spring oscillation and eventual settling
      controller.tick(const Duration(milliseconds: 1500));
      final settledDeflection = controller.getBubbleDeflection(platform.id);
      expect(settledDeflection.abs(), lessThan(1.0));
      expect(
        controller.position.dy,
        closeTo(expectedBaseY + settledDeflection, 0.001),
      );
    },
  );

  test(
    'spawns alternating paw prints during walk/run and decays over time',
    () {
      final controller = PetWorldController();
      controller.loadRoom(FakeChatRepository.rooms.first);

      expect(controller.pawPrints, isEmpty);

      // Progress into walk state (starts after 1.5s idle)
      controller.tick(const Duration(milliseconds: 1600));
      expect(controller.state, PetState.walk);

      // Walk for 600ms (at 0.24s step interval, should produce 2-3 paw prints)
      controller.tick(const Duration(milliseconds: 600));
      expect(controller.pawPrints, isNotEmpty);
      expect(controller.pawPrints.length, greaterThanOrEqualTo(2));

      // Paws alternate left and right
      final paw1 = controller.pawPrints[0];
      final paw2 = controller.pawPrints[1];
      expect(paw1.isLeftPaw, isNot(equals(paw2.isLeftPaw)));
      expect(paw1.opacity, greaterThan(0.0));

      // Progress time beyond maxLifetime (2.8s) -> old paw prints should expire
      controller.tick(const Duration(milliseconds: 3200));
      expect(controller.pawPrints.contains(paw1), isFalse);
    },
  );

  test(
    'projects surface shadow accurately across ground, airborne jump, and bouncing platform',
    () {
      final controller = PetWorldController();
      controller.loadRoom(FakeChatRepository.rooms.first);
      _measureTargets(controller);

      // 1. On ground
      expect(controller.heightAboveSurface, 0.0);
      expect(controller.currentSurfaceY, controller.position.dy + 52.0);

      // 2. Mid-jump airborne arc
      final platform = controller.objects.firstWhere(
        (object) => object.kind == WorldObjectKind.platform,
      );
      controller.interact(platform.id);

      // Tick to midway through jump
      controller.tick(const Duration(milliseconds: 275));
      expect(controller.state, PetState.jump);
      expect(controller.heightAboveSurface, greaterThan(25.0));
      // Dog is higher in the air than the surface below it
      expect(
        controller.position.dy + 52.0,
        lessThan(controller.currentSurfaceY),
      );
      expect(
        controller.currentSurfaceY - (controller.position.dy + 52.0),
        closeTo(controller.heightAboveSurface, 0.1),
      );

      // 3. Landing & platform spring bounce
      controller.tick(const Duration(milliseconds: 300)); // Complete landing
      expect(controller.heightAboveSurface, 0.0);

      // Deflect spring
      controller.tick(const Duration(milliseconds: 40));
      final deflection = controller.getBubbleDeflection(platform.id);
      expect(
        controller.currentSurfaceY,
        closeTo(platform.bounds.top + deflection, 0.001),
      );
      expect(
        controller.position.dy,
        closeTo(platform.bounds.top - 52.0 + deflection, 0.001),
      );
    },
  );

  test(
    'switching pets updates selectedPet, petConfig, and spawns signature particles',
    () {
      final controller = PetWorldController();
      expect(controller.selectedPet, PetType.corgi);
      expect(controller.petConfig.type, PetType.corgi);

      // Switch to Cat
      controller.setPet(PetType.cat);
      expect(controller.selectedPet, PetType.cat);
      expect(controller.petConfig.displayName, contains('貓咪'));
      expect(controller.petConfig.avatarEmoji, '🐱');
      expect(controller.petConfig.trailAsset, 'assets/pets/cat_paw.png');
      expect(
        controller.particles.any((p) => p.kind == ParticleKind.heart),
        isTrue,
      );

      // Switch to Parrot
      controller.setPet(PetType.parrot);
      expect(controller.selectedPet, PetType.parrot);
      expect(controller.petConfig.displayName, contains('鸚鵡'));
      expect(controller.petConfig.avatarEmoji, '🦜');
      expect(controller.petConfig.trailAsset, 'assets/pets/parrot_paw.png');
      expect(controller.petConfig.isBird, isTrue);
      expect(
        controller.particles.any((p) => p.kind == ParticleKind.note),
        isTrue,
      );
    },
  );
}

void _measureTargets(PetWorldController controller) {
  controller.updateObjectBounds({
    for (final target in controller.objects)
      target.id: const Rect.fromLTWH(100, 200, 180, 52),
  });
}
