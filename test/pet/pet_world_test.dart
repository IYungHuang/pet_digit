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
