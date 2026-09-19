import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/pet/domain/pet_behavior_catalog.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_normalizer.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_runtime.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_content_kind.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_target.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world_controller.dart';

void main() {
  test('interact delegates a user tap to dispatch', () {
    final controller = PetWorldController();
    final target = _target(
      id: 'emoji',
      kind: WorldObjectKind.emojiToy,
      contentKind: PetNormalizedContentKind.emoji,
      payload: '🪀',
    );
    controller.objects = [target];

    final result = controller.interact(target.id);

    expect(result.status, PetBehaviorExecutionStatus.executed);
    expect(controller.currentAction, PetActionType.chaseEmoji);
    expect(controller.bouncingToy?.emoji, '🪀');
  });

  test(
    'dispatch ignores selector null without changing active runtime state',
    () {
      final controller = PetWorldController();
      final activeTarget = _target(
        id: 'active',
        kind: WorldObjectKind.emojiToy,
        contentKind: PetNormalizedContentKind.emoji,
        payload: '🎾',
      );
      controller.objects = [activeTarget];
      controller.interact(activeTarget.id);
      final actionBefore = controller.currentAction;
      final targetBefore = controller.activeTarget;

      final result = controller.dispatch(
        PetBehaviorStimulus(
          stimulusType: PetStimulusType.loudSound,
          petType: controller.selectedPet,
          targetId: activeTarget.id,
          targetKind: activeTarget.kind,
          contentKind: activeTarget.contentKind,
          payload: activeTarget.payload,
        ),
      );

      expect(result.status, PetBehaviorExecutionStatus.ignored);
      expect(result.reason, contains('no selection'));
      expect(controller.currentAction, actionBefore);
      expect(controller.activeTarget, same(targetBefore));
    },
  );

  test('dispatch ignores target without measured bounds', () {
    final controller = PetWorldController();
    final target = PetMessageTarget(
      id: 'unready',
      kind: WorldObjectKind.platform,
      contentKind: PetNormalizedContentKind.text,
      payload: 'hello',
      messageText: 'hello',
    );
    controller.objects = [target];

    final result = controller.dispatch(
      PetBehaviorNormalizer.fromTarget(
        target,
        PetStimulusType.userTap,
        petType: controller.selectedPet,
      ),
    );

    expect(result.status, PetBehaviorExecutionStatus.ignored);
    expect(controller.currentAction, PetActionType.none);
    expect(controller.activeTarget, isNull);
  });

  test('landed target keeps updated live bounds on subsequent tick', () {
    final controller = PetWorldController();
    final platform = _target(
      id: 'platform',
      kind: WorldObjectKind.platform,
      contentKind: PetNormalizedContentKind.text,
      payload: 'hello',
    );
    controller.objects = [platform];

    controller.interact(platform.id);
    controller.tick(const Duration(milliseconds: 600));
    controller.updateObjectBounds({
      platform.id: const Rect.fromLTWH(120, 300, 180, 52),
    });
    controller.tick(const Duration(milliseconds: 16));

    expect(controller.currentPlatform, same(platform));
    expect(
      controller.position.dy,
      closeTo(248 + controller.getBubbleDeflection(platform.id), 0.001),
    );
  });

  test('cat stalk pauses before probing twice and returning idle', () {
    final controller = PetWorldController()..selectedPet = PetType.cat;
    final media = _target(
      id: 'photo',
      kind: WorldObjectKind.animatedToy,
      contentKind: PetNormalizedContentKind.image,
      payload: 'https://example.test/photo.png',
    );
    controller.objects = [media];

    final result = controller.dispatch(
      PetBehaviorNormalizer.fromTarget(
        media,
        PetStimulusType.newMessageBubble,
        petType: PetType.cat,
      ),
    );
    expect(result.status, PetBehaviorExecutionStatus.executed);
    expect(controller.currentAction, PetActionType.pawTest);

    controller.tick(const Duration(milliseconds: 300));
    expect(controller.state, PetState.catStalk);
    expect(controller.position, const Offset(24, 24));

    controller.tick(const Duration(milliseconds: 500));
    expect(controller.position.dx, greaterThan(24));
    expect(controller.position.dx, lessThan(64));

    controller.tick(const Duration(milliseconds: 200));
    final pausedAt = controller.position;
    controller.tick(const Duration(milliseconds: 300));
    expect(controller.position, pausedAt);

    controller.tick(const Duration(milliseconds: 600));
    expect(controller.state, PetState.pawTest);
    expect(controller.position.dx, closeTo(48, 0.001));

    controller.tick(const Duration(milliseconds: 300));
    controller.tick(const Duration(milliseconds: 16));
    expect(controller.getBubbleDeflection(media.id), isNot(0));

    controller.tick(const Duration(milliseconds: 1100));
    expect(controller.currentAction, PetActionType.none);
    expect(controller.state, PetState.idle);
  });

  test('cat paw test follows live bubble bounds while timeline moves', () {
    final controller = PetWorldController()..selectedPet = PetType.cat;
    final media = _target(
      id: 'moving-photo',
      kind: WorldObjectKind.animatedToy,
      contentKind: PetNormalizedContentKind.image,
      payload: 'https://example.test/photo.png',
    );
    controller.objects = [media];
    controller.dispatch(
      PetBehaviorNormalizer.fromTarget(
        media,
        PetStimulusType.newMessageBubble,
        petType: PetType.cat,
      ),
    );
    controller.tick(const Duration(milliseconds: 1700));

    controller.updateObjectBounds({
      media.id: const Rect.fromLTWH(700, 900, 180, 52),
    });
    controller.tick(const Duration(milliseconds: 16));

    expect(controller.position, const Offset(628, 900));
  });

  test('cat paw test uses bubble right side when left side is offscreen', () {
    final controller = PetWorldController()..selectedPet = PetType.cat;
    final media = _target(
      id: 'left-photo',
      kind: WorldObjectKind.animatedToy,
      contentKind: PetNormalizedContentKind.image,
      payload: 'https://example.test/photo.png',
    );
    media.markMeasuredBounds(const Rect.fromLTWH(18, 180, 222, 52));
    controller.objects = [media];
    controller.dispatch(
      PetBehaviorNormalizer.fromTarget(
        media,
        PetStimulusType.newMessageBubble,
        petType: PetType.cat,
      ),
    );

    expect(controller.direction, 1);

    controller.tick(const Duration(milliseconds: 1700));

    expect(controller.position, const Offset(248, 180));
    expect(controller.direction, -1);

    controller.updateObjectBounds({
      media.id: const Rect.fromLTWH(80, 180, 222, 52),
    });
    controller.tick(const Duration(milliseconds: 16));

    expect(controller.position, const Offset(310, 180));
    expect(controller.direction, -1);
  });

  test('message-side target stays inside a narrow viewport', () {
    final controller = PetWorldController()
      ..selectedPet = PetType.cat
      ..updateViewportSize(const Size(260, 600));
    final media = _target(
      id: 'narrow-photo',
      kind: WorldObjectKind.animatedToy,
      contentKind: PetNormalizedContentKind.image,
      payload: 'https://example.test/photo.png',
    );
    media.markMeasuredBounds(const Rect.fromLTWH(18, 180, 222, 52));
    controller.objects = [media];
    controller.dispatch(
      PetBehaviorNormalizer.fromTarget(
        media,
        PetStimulusType.newMessageBubble,
        petType: PetType.cat,
      ),
    );

    controller.tick(const Duration(milliseconds: 1700));

    expect(controller.position.dx, inInclusiveRange(0, 196));
  });

  test('message-side target stays inside viewport vertically', () {
    for (final testCase in <({Rect bounds, double expectedY})>[
      (bounds: const Rect.fromLTWH(80, -120, 100, 52), expectedY: 0),
      (bounds: const Rect.fromLTWH(80, 700, 100, 52), expectedY: 536),
    ]) {
      final controller = PetWorldController()
        ..selectedPet = PetType.cat
        ..updateViewportSize(const Size(260, 600));
      final media = _target(
        id: 'vertical-photo',
        kind: WorldObjectKind.animatedToy,
        contentKind: PetNormalizedContentKind.image,
        payload: 'https://example.test/photo.png',
      );
      media.markMeasuredBounds(testCase.bounds);
      controller.objects = [media];
      controller.dispatch(
        PetBehaviorNormalizer.fromTarget(
          media,
          PetStimulusType.newMessageBubble,
          petType: PetType.cat,
        ),
      );

      controller.tick(const Duration(milliseconds: 1700));

      expect(controller.position.dy, testCase.expectedY);
    }
  });

  test('text approach uses clamped message-side position', () {
    for (final testCase in <({Rect bounds, Offset expected})>[
      (
        bounds: const Rect.fromLTWH(18, -120, 222, 52),
        expected: const Offset(196, 0),
      ),
      (
        bounds: const Rect.fromLTWH(80, 700, 100, 52),
        expected: const Offset(8, 536),
      ),
    ]) {
      final controller = PetWorldController()
        ..updateViewportSize(const Size(260, 600));
      final text = _target(
        id: 'vertical-text',
        kind: WorldObjectKind.platform,
        contentKind: PetNormalizedContentKind.text,
        payload: 'hello',
      );
      text.markMeasuredBounds(testCase.bounds);
      controller.objects = [text];

      controller.startObserveTarget(text, walkToward: true);
      controller.tick(const Duration(seconds: 10));

      expect(controller.position, testCase.expected);
    }
  });

  test('media probe follows bubble spring deflection', () {
    final controller = PetWorldController();
    final media = _target(
      id: 'spring-photo',
      kind: WorldObjectKind.animatedToy,
      contentKind: PetNormalizedContentKind.image,
      payload: 'https://example.test/photo.png',
    );
    controller.objects = [media];
    controller.dispatch(
      PetBehaviorNormalizer.fromTarget(
        media,
        PetStimulusType.newMessageBubble,
        petType: PetType.corgi,
      ),
    );

    controller.tick(const Duration(milliseconds: 1700));
    controller.tick(const Duration(milliseconds: 16));

    final deflection = controller.getBubbleDeflection(media.id);
    expect(deflection, isNot(0));
    expect(controller.position.dy, closeTo(180 + deflection, 0.001));
  });

  test('cat paw test preserves both impacts across a large tick', () {
    final controller = PetWorldController()..selectedPet = PetType.cat;
    final media = _target(
      id: 'photo',
      kind: WorldObjectKind.animatedToy,
      contentKind: PetNormalizedContentKind.image,
      payload: 'https://example.test/photo.png',
    );
    controller.objects = [media];
    controller.dispatch(
      PetBehaviorNormalizer.fromTarget(
        media,
        PetStimulusType.newMessageBubble,
        petType: PetType.cat,
      ),
    );
    final notifierBefore = controller.springNotifier.value;

    controller.tick(const Duration(milliseconds: 3100));

    expect(controller.springNotifier.value, notifierBefore + 2);
    expect(controller.currentAction, PetActionType.none);
    controller.tick(const Duration(milliseconds: 16));
    expect(controller.getBubbleDeflection(media.id), isNot(0));
  });

  test('cat paw test exposes all six sprite frames in order', () {
    final controller = PetWorldController()..selectedPet = PetType.cat;
    final media = _target(
      id: 'photo',
      kind: WorldObjectKind.animatedToy,
      contentKind: PetNormalizedContentKind.image,
      payload: 'https://example.test/photo.png',
    );
    controller.objects = [media];
    controller.dispatch(
      PetBehaviorNormalizer.fromTarget(
        media,
        PetStimulusType.newMessageBubble,
        petType: PetType.cat,
      ),
    );

    controller.tick(const Duration(milliseconds: 1700));
    expect(controller.frameIndex, 0);
    for (var frame = 1; frame < 6; frame++) {
      controller.tick(const Duration(milliseconds: 150));
      expect(controller.frameIndex, frame);
    }
  });

  test('dog arcs in, sniffs, nose-touches, and evaluates new media', () {
    final controller = PetWorldController();
    final media = _target(
      id: 'dog-media',
      kind: WorldObjectKind.animatedToy,
      contentKind: PetNormalizedContentKind.gif,
      payload: 'https://example.test/dog.gif',
    );
    controller.objects = [media];

    final result = controller.dispatch(
      PetBehaviorNormalizer.fromTarget(
        media,
        PetStimulusType.newMessageBubble,
        petType: PetType.corgi,
      ),
    );

    expect(result.status, PetBehaviorExecutionStatus.executed);
    expect(controller.currentAction, PetActionType.dogProbe);
    expect(controller.frameIndex, 0);
    final start = controller.position;
    controller.tick(const Duration(milliseconds: 200));
    expect(controller.position, start);
    expect(controller.frameIndex, 1);

    controller.tick(const Duration(milliseconds: 450));
    expect(controller.frameIndex, 2);
    controller.tick(const Duration(milliseconds: 350));
    expect(controller.position, const Offset(48, 180));
    expect(controller.frameIndex, 3);

    final notifierBefore = controller.springNotifier.value;
    controller.tick(const Duration(milliseconds: 700));
    expect(controller.springNotifier.value, notifierBefore + 1);
    expect(controller.frameIndex, 4);
    expect(controller.state, PetState.dogProbe);

    controller.tick(const Duration(milliseconds: 600));
    expect(controller.frameIndex, 5);
    controller.tick(const Duration(milliseconds: 500));
    expect(controller.currentAction, PetActionType.none);
    expect(controller.state, PetState.idle);
  });

  test(
    'parrot side-steps, inspects with one eye, and beak-tests new media',
    () {
      final controller = PetWorldController()..selectedPet = PetType.parrot;
      final media = _target(
        id: 'parrot-media',
        kind: WorldObjectKind.animatedToy,
        contentKind: PetNormalizedContentKind.video,
        payload: 'https://example.test/parrot.mp4',
      );
      controller.objects = [media];

      final result = controller.dispatch(
        PetBehaviorNormalizer.fromTarget(
          media,
          PetStimulusType.newMessageBubble,
          petType: PetType.parrot,
        ),
      );

      expect(result.status, PetBehaviorExecutionStatus.executed);
      expect(controller.frameIndex, 0);
      final start = controller.position;
      controller.tick(const Duration(milliseconds: 200));
      expect(controller.position, start);
      expect(controller.frameIndex, 1);

      controller.tick(const Duration(milliseconds: 250));
      expect(controller.frameIndex, 2);
      controller.tick(const Duration(milliseconds: 250));
      expect(controller.position.dx, greaterThan(start.dx));
      expect(controller.frameIndex, 3);

      final inspectPosition = controller.position;
      controller.tick(const Duration(milliseconds: 1000));
      expect(controller.position, inspectPosition);
      expect(controller.frameIndex, 4);

      final notifierBefore = controller.springNotifier.value;
      controller.tick(const Duration(milliseconds: 600));
      expect(controller.springNotifier.value, greaterThan(notifierBefore));
      expect(controller.frameIndex, 5);
      expect(controller.state, PetState.parrotProbe);

      controller.tick(const Duration(milliseconds: 500));
      expect(controller.currentAction, PetActionType.none);
      expect(controller.state, PetState.idle);
    },
  );
}

PetMessageTarget _target({
  required String id,
  required WorldObjectKind kind,
  required PetNormalizedContentKind contentKind,
  required Object? payload,
}) {
  final target = PetMessageTarget(
    id: id,
    kind: kind,
    contentKind: contentKind,
    payload: payload,
    messageText: '$payload',
  );
  target.markMeasuredBounds(const Rect.fromLTWH(120, 180, 180, 52));
  return target;
}
