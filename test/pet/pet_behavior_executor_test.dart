import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/pet/domain/pet_behavior_catalog.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_executor.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_runtime.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_content_kind.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_target.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world_controller.dart';

void main() {
  test('platform user tap starts jump runtime', () {
    final controller = PetWorldController();
    final target = _target(
      kind: WorldObjectKind.platform,
      contentKind: PetNormalizedContentKind.text,
      payload: 'hello',
    );

    final result = PetBehaviorExecutor(controller).execute(
      _selection(PetBehaviorAction.nosePawBump, PetBehaviorCapability.native),
      target,
    );

    expect(result.status, PetBehaviorExecutionStatus.executed);
    expect(controller.currentAction, PetActionType.jumpToPlatform);
    expect(controller.state, PetState.jump);
    expect(controller.activeTarget?.id, target.id);
  });

  test('emoji user tap passes normalized payload to chase runtime', () {
    final controller = PetWorldController();
    final target = _target(
      kind: WorldObjectKind.emojiToy,
      contentKind: PetNormalizedContentKind.emoji,
      payload: '🧶',
    );

    final result = PetBehaviorExecutor(controller).execute(
      _selection(PetBehaviorAction.runChase, PetBehaviorCapability.native),
      target,
    );

    expect(result.status, PetBehaviorExecutionStatus.executed);
    expect(controller.currentAction, PetActionType.chaseEmoji);
    expect(controller.bouncingToy?.emoji, '🧶');
  });

  test('media user tap starts inspect runtime', () {
    final controller = PetWorldController();
    final target = _target(
      kind: WorldObjectKind.animatedToy,
      contentKind: PetNormalizedContentKind.gif,
      payload: 'https://example.test/pet.gif',
    );

    final result = PetBehaviorExecutor(controller).execute(
      _selection(PetBehaviorAction.sniffBubble, PetBehaviorCapability.degraded),
      target,
    );

    expect(result.status, PetBehaviorExecutionStatus.fallback);
    expect(controller.currentAction, PetActionType.inspectGif);
    expect(controller.state, PetState.observe);
    expect(controller.activeTarget?.id, target.id);
  });

  test('circle sniff degrades to walk-toward observe runtime', () {
    final controller = PetWorldController();
    final target = _target(
      kind: WorldObjectKind.platform,
      contentKind: PetNormalizedContentKind.text,
      payload: 'new item',
    );

    final result = PetBehaviorExecutor(controller).execute(
      _selection(PetBehaviorAction.circleSniff, PetBehaviorCapability.degraded),
      target,
    );

    expect(result.status, PetBehaviorExecutionStatus.fallback);
    expect(controller.currentAction, PetActionType.observeTarget);
    expect(controller.state, PetState.walk);
    expect(controller.activeTarget?.id, target.id);
  });

  test('unsupported action is ignored without fake motion', () {
    final controller = PetWorldController();
    final activeTarget = _target(
      kind: WorldObjectKind.emojiToy,
      contentKind: PetNormalizedContentKind.emoji,
      payload: '🎾',
    );
    PetBehaviorExecutor(controller).execute(
      _selection(PetBehaviorAction.runChase, PetBehaviorCapability.native),
      activeTarget,
    );
    final actionBefore = controller.currentAction;
    final targetBefore = controller.activeTarget;
    final stateBefore = controller.state;

    final result = PetBehaviorExecutor(controller).execute(
      _selection(PetBehaviorAction.flyBack, PetBehaviorCapability.unsupported),
      _target(
        kind: WorldObjectKind.platform,
        contentKind: PetNormalizedContentKind.text,
        payload: 'not flight',
      ),
    );

    expect(result.status, PetBehaviorExecutionStatus.ignored);
    expect(result.reason, contains('flyBack'));
    expect(controller.currentAction, actionBefore);
    expect(controller.activeTarget, same(targetBefore));
    expect(controller.state, stateBefore);
  });

  test('unready target is ignored without changing active runtime state', () {
    final controller = PetWorldController();
    final activeTarget = _target(
      kind: WorldObjectKind.emojiToy,
      contentKind: PetNormalizedContentKind.emoji,
      payload: '🎾',
    );
    PetBehaviorExecutor(controller).execute(
      _selection(PetBehaviorAction.runChase, PetBehaviorCapability.native),
      activeTarget,
    );
    final actionBefore = controller.currentAction;
    final targetBefore = controller.activeTarget;

    final unready = PetMessageTarget(
      id: 'unready',
      kind: WorldObjectKind.platform,
      contentKind: PetNormalizedContentKind.text,
      payload: 'hello',
      messageText: 'hello',
    );
    final result = PetBehaviorExecutor(controller).execute(
      _selection(PetBehaviorAction.nosePawBump, PetBehaviorCapability.native),
      unready,
    );

    expect(result.status, PetBehaviorExecutionStatus.ignored);
    expect(controller.currentAction, actionBefore);
    expect(controller.activeTarget, same(targetBefore));
  });
}

PetBehaviorSelection _selection(
  PetBehaviorAction action,
  PetBehaviorCapability capability,
) => PetBehaviorSelection(
  action: action,
  stimulusType: PetStimulusType.userTap,
  targetId: 'target',
  capability: capability,
  reason: 'test:$action',
);

PetMessageTarget _target({
  required WorldObjectKind kind,
  required PetNormalizedContentKind contentKind,
  required Object? payload,
}) {
  final target = PetMessageTarget(
    id: 'target',
    kind: kind,
    contentKind: contentKind,
    payload: payload,
    messageText: '$payload',
  );
  target.markMeasuredBounds(const Rect.fromLTWH(120, 180, 180, 52));
  return target;
}
