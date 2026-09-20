import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/pet/domain/pet_behavior_catalog.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_executor.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_runtime.dart';
import 'package:chat_pet_mvp/pet/domain/pet_action_plan.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_content_kind.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_target.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world_controller.dart';

void main() {
  group('immutable action-plan boundary', () {
    final cases =
        <
          ({
            PetBehaviorAction action,
            PetBehaviorCapability capability,
            PetStimulusType stimulus,
            WorldObjectKind targetKind,
            PetRuntimeAction runtimeAction,
            PetBehaviorExecutionStatus status,
            bool walkToward,
            bool carriesPayload,
          })
        >[
          (
            action: PetBehaviorAction.nosePawBump,
            capability: PetBehaviorCapability.native,
            stimulus: PetStimulusType.userTap,
            targetKind: WorldObjectKind.platform,
            runtimeAction: PetRuntimeAction.jumpToPlatform,
            status: PetBehaviorExecutionStatus.executed,
            walkToward: false,
            carriesPayload: false,
          ),
          (
            action: PetBehaviorAction.headBuntRub,
            capability: PetBehaviorCapability.degraded,
            stimulus: PetStimulusType.userTap,
            targetKind: WorldObjectKind.platform,
            runtimeAction: PetRuntimeAction.jumpToPlatform,
            status: PetBehaviorExecutionStatus.fallback,
            walkToward: false,
            carriesPayload: false,
          ),
          (
            action: PetBehaviorAction.runChase,
            capability: PetBehaviorCapability.native,
            stimulus: PetStimulusType.emoji,
            targetKind: WorldObjectKind.emojiToy,
            runtimeAction: PetRuntimeAction.chaseEmoji,
            status: PetBehaviorExecutionStatus.executed,
            walkToward: false,
            carriesPayload: true,
          ),
          (
            action: PetBehaviorAction.sniffBubble,
            capability: PetBehaviorCapability.degraded,
            stimulus: PetStimulusType.gif,
            targetKind: WorldObjectKind.animatedToy,
            runtimeAction: PetRuntimeAction.inspectMedia,
            status: PetBehaviorExecutionStatus.fallback,
            walkToward: false,
            carriesPayload: true,
          ),
          (
            action: PetBehaviorAction.circleSniff,
            capability: PetBehaviorCapability.degraded,
            stimulus: PetStimulusType.newMessageBubble,
            targetKind: WorldObjectKind.platform,
            runtimeAction: PetRuntimeAction.observeTarget,
            status: PetBehaviorExecutionStatus.fallback,
            walkToward: true,
            carriesPayload: false,
          ),
          (
            action: PetBehaviorAction.pawTest,
            capability: PetBehaviorCapability.native,
            stimulus: PetStimulusType.newMessageBubble,
            targetKind: WorldObjectKind.animatedToy,
            runtimeAction: PetRuntimeAction.catPawTest,
            status: PetBehaviorExecutionStatus.executed,
            walkToward: false,
            carriesPayload: false,
          ),
          (
            action: PetBehaviorAction.novelObjectNoseProbe,
            capability: PetBehaviorCapability.native,
            stimulus: PetStimulusType.newMessageBubble,
            targetKind: WorldObjectKind.animatedToy,
            runtimeAction: PetRuntimeAction.dogProbe,
            status: PetBehaviorExecutionStatus.executed,
            walkToward: false,
            carriesPayload: false,
          ),
          (
            action: PetBehaviorAction.beakProbe,
            capability: PetBehaviorCapability.native,
            stimulus: PetStimulusType.newMessageBubble,
            targetKind: WorldObjectKind.animatedToy,
            runtimeAction: PetRuntimeAction.parrotProbe,
            status: PetBehaviorExecutionStatus.executed,
            walkToward: false,
            carriesPayload: false,
          ),
        ];

    for (final testCase in cases) {
      test('${testCase.action.name} emits exactly one action plan', () {
        final runtime = _RecordingRuntime();
        final payload = <String, Object?>{'value': testCase.action.name};
        final target = _target(
          kind: testCase.targetKind,
          contentKind: _contentKindFor(testCase.targetKind),
          payload: payload,
        );

        final result = PetBehaviorExecutor(runtime).execute(
          _selection(
            testCase.action,
            testCase.capability,
            stimulusType: testCase.stimulus,
          ),
          target,
        );

        expect(runtime.calls, hasLength(1));
        expect(runtime.targets.single, same(target));
        expect(runtime.calls.single.runtimeAction, testCase.runtimeAction);
        expect(runtime.calls.single.catalogAction, testCase.action);
        expect(runtime.calls.single.originTargetId, target.id);
        expect(runtime.calls.single.walkToward, testCase.walkToward);
        expect(
          runtime.calls.single.payload,
          testCase.carriesPayload ? same(payload) : isNull,
        );
        expect(result.status, testCase.status);
        expect(result.action, testCase.action);
        expect(result.targetId, target.id);
        expect(result.reason, isNotEmpty);
      });
    }

    for (final action in PetBehaviorAction.values) {
      test('${action.name} has one deterministic runtime decision', () {
        final expectation = _expectationFor(action);
        final runtime = _RecordingRuntime();
        final target = _target(
          kind: expectation.targetKind,
          contentKind: _contentKindFor(expectation.targetKind),
          payload: 'payload:${action.name}',
        );

        final result = PetBehaviorExecutor(runtime).execute(
          _selection(
            action,
            expectation.status == PetBehaviorExecutionStatus.executed
                ? PetBehaviorCapability.native
                : PetBehaviorCapability.unsupported,
            stimulusType: expectation.stimulus,
          ),
          target,
        );

        expect(result.status, expectation.status);
        expect(result.action, action);
        expect(result.reason, expectation.reason);
        if (expectation.runtimeAction == null) {
          expect(runtime.calls, isEmpty);
        } else {
          expect(runtime.calls, hasLength(1));
          expect(runtime.calls.single.runtimeAction, expectation.runtimeAction);
          expect(runtime.calls.single.catalogAction, action);
          expect(runtime.calls.single.originTargetId, target.id);
          expect(runtime.calls.single.walkToward, expectation.walkToward);
          expect(
            runtime.calls.single.payload,
            expectation.carriesPayload ? same(target.payload) : isNull,
          );
        }
      });
    }

    test('invalid jump target throws before mutating active runtime', () {
      final controller = PetWorldController();
      final chaseTarget = _target(
        kind: WorldObjectKind.emojiToy,
        contentKind: PetNormalizedContentKind.emoji,
        payload: '🎾',
      );
      controller.startChaseEmoji(chaseTarget, payload: chaseTarget.payload);
      final actionBefore = controller.currentAction;
      final stateBefore = controller.state;
      final targetBefore = controller.activeTarget;
      final payloadBefore = controller.activePayload;
      final toyBefore = controller.bouncingToy;

      expect(
        () => controller.startAction(
          const PetActionPlan(
            runtimeAction: PetRuntimeAction.jumpToPlatform,
            catalogAction: PetBehaviorAction.nosePawBump,
            originTargetId: 'invalid',
          ),
          const _UnboundedTarget(),
        ),
        throwsArgumentError,
      );

      expect(controller.currentAction, actionBefore);
      expect(controller.state, stateBefore);
      expect(controller.activeTarget, same(targetBefore));
      expect(controller.activePayload, same(payloadBefore));
      expect(controller.bouncingToy, same(toyBefore));
    });

    test('unsupported capability can still use explicit fallback plan', () {
      final runtime = _RecordingRuntime();
      final target = _target(
        kind: WorldObjectKind.platform,
        contentKind: PetNormalizedContentKind.text,
        payload: 'unknown object',
      );

      final result = PetBehaviorExecutor(runtime).execute(
        _selection(
          PetBehaviorAction.hidePeek,
          PetBehaviorCapability.unsupported,
        ),
        target,
      );

      expect(result.status, PetBehaviorExecutionStatus.fallback);
      expect(runtime.calls, hasLength(1));
      expect(
        runtime.calls.single.runtimeAction,
        PetRuntimeAction.observeTarget,
      );
      expect(runtime.calls.single.catalogAction, PetBehaviorAction.hidePeek);
    });

    test('wrong target kind emits one stationary observe fallback', () {
      final runtime = _RecordingRuntime();
      final target = _target(
        kind: WorldObjectKind.platform,
        contentKind: PetNormalizedContentKind.text,
        payload: 'not media',
      );

      final result = PetBehaviorExecutor(runtime).execute(
        _selection(PetBehaviorAction.pawTest, PetBehaviorCapability.native),
        target,
      );

      expect(result.status, PetBehaviorExecutionStatus.fallback);
      expect(result.reason, 'media target required');
      expect(runtime.calls, hasLength(1));
      expect(
        runtime.calls.single.runtimeAction,
        PetRuntimeAction.observeTarget,
      );
      expect(runtime.calls.single.walkToward, isFalse);
    });

    for (final scenario
        in <
          ({
            String name,
            PetMessageTarget target,
            PetBehaviorSelection selection,
          })
        >[
          (
            name: 'selection target mismatch',
            target: _target(
              kind: WorldObjectKind.platform,
              contentKind: PetNormalizedContentKind.text,
              payload: 'text',
            ),
            selection: _selection(
              PetBehaviorAction.nosePawBump,
              PetBehaviorCapability.native,
              targetId: 'different',
            ),
          ),
          (
            name: 'unmeasured target',
            target: PetMessageTarget(
              id: 'target',
              kind: WorldObjectKind.platform,
              contentKind: PetNormalizedContentKind.text,
              payload: 'text',
              messageText: 'text',
            ),
            selection: _selection(
              PetBehaviorAction.nosePawBump,
              PetBehaviorCapability.native,
            ),
          ),
          (
            name: 'true ignored action',
            target: _target(
              kind: WorldObjectKind.platform,
              contentKind: PetNormalizedContentKind.text,
              payload: 'text',
            ),
            selection: _selection(
              PetBehaviorAction.flyBack,
              PetBehaviorCapability.unsupported,
            ),
          ),
        ]) {
      test('${scenario.name} makes zero runtime calls', () {
        final runtime = _RecordingRuntime();

        final result = PetBehaviorExecutor(
          runtime,
        ).execute(scenario.selection, scenario.target);

        expect(result.status, PetBehaviorExecutionStatus.ignored);
        expect(runtime.calls, isEmpty);
        expect(runtime.targets, isEmpty);
      });
    }
  });

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

  test('dog media user tap preserves legacy inspect fallback', () {
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

  test('cat paw test action starts dedicated native runtime', () {
    final controller = PetWorldController()..selectedPet = PetType.cat;
    final target = _target(
      kind: WorldObjectKind.animatedToy,
      contentKind: PetNormalizedContentKind.image,
      payload: 'https://example.test/photo.png',
    );

    final result = PetBehaviorExecutor(controller).execute(
      _selection(
        PetBehaviorAction.pawTest,
        PetBehaviorCapability.native,
        stimulusType: PetStimulusType.newMessageBubble,
      ),
      target,
    );

    expect(result.status, PetBehaviorExecutionStatus.executed);
    expect(controller.currentAction, PetActionType.pawTest);
    expect(controller.state, PetState.catStalk);
    expect(controller.activeTarget?.id, target.id);
  });

  test('new cat media starts low stalking paw probe', () {
    final controller = PetWorldController()..selectedPet = PetType.cat;
    final target = _target(
      kind: WorldObjectKind.animatedToy,
      contentKind: PetNormalizedContentKind.image,
      payload: 'https://example.test/photo.png',
    );

    final result = PetBehaviorExecutor(controller).execute(
      _selection(
        PetBehaviorAction.pawTest,
        PetBehaviorCapability.native,
        stimulusType: PetStimulusType.newMessageBubble,
      ),
      target,
    );

    expect(result.status, PetBehaviorExecutionStatus.executed);
    expect(controller.currentAction, PetActionType.pawTest);
    expect(controller.state, PetState.catStalk);
  });

  test('new dog media starts sniff and nose probe runtime', () {
    final controller = PetWorldController();
    final target = _target(
      kind: WorldObjectKind.animatedToy,
      contentKind: PetNormalizedContentKind.gif,
      payload: 'https://example.test/clip.gif',
    );

    final result = PetBehaviorExecutor(controller).execute(
      _selection(
        PetBehaviorAction.novelObjectNoseProbe,
        PetBehaviorCapability.native,
        stimulusType: PetStimulusType.newMessageBubble,
      ),
      target,
    );

    expect(result.status, PetBehaviorExecutionStatus.executed);
    expect(controller.currentAction, PetActionType.dogProbe);
    expect(controller.state, PetState.dogProbe);
  });

  test('new parrot media starts monocular beak probe runtime', () {
    final controller = PetWorldController()..selectedPet = PetType.parrot;
    final target = _target(
      kind: WorldObjectKind.animatedToy,
      contentKind: PetNormalizedContentKind.video,
      payload: 'https://example.test/clip.mp4',
    );

    final result = PetBehaviorExecutor(controller).execute(
      _selection(
        PetBehaviorAction.beakProbe,
        PetBehaviorCapability.native,
        stimulusType: PetStimulusType.newMessageBubble,
      ),
      target,
    );

    expect(result.status, PetBehaviorExecutionStatus.executed);
    expect(controller.currentAction, PetActionType.parrotProbe);
    expect(controller.state, PetState.parrotProbe);
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

  test('fallback observe clears a landed platform runtime', () {
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

    final result = PetBehaviorExecutor(controller).execute(
      _selection(
        PetBehaviorAction.hidePeek,
        PetBehaviorCapability.unsupported,
        targetId: 'observe',
      ),
      _target(
        id: 'observe',
        kind: WorldObjectKind.platform,
        contentKind: PetNormalizedContentKind.text,
        payload: 'new object',
      ),
    );

    expect(result.status, PetBehaviorExecutionStatus.fallback);
    expect(controller.currentAction, PetActionType.observeTarget);
    expect(controller.currentPlatform, isNull);
  });

  test('circle fallback clears an active chase toy', () {
    final controller = PetWorldController();
    final target = _target(
      kind: WorldObjectKind.emojiToy,
      contentKind: PetNormalizedContentKind.emoji,
      payload: '🎾',
    );
    PetBehaviorExecutor(controller).execute(
      _selection(PetBehaviorAction.runChase, PetBehaviorCapability.native),
      target,
    );

    final result = PetBehaviorExecutor(controller).execute(
      _selection(
        PetBehaviorAction.circleSniff,
        PetBehaviorCapability.degraded,
        targetId: 'circle',
      ),
      _target(
        id: 'circle',
        kind: WorldObjectKind.platform,
        contentKind: PetNormalizedContentKind.text,
        payload: 'new object',
      ),
    );

    expect(result.status, PetBehaviorExecutionStatus.fallback);
    expect(controller.currentAction, PetActionType.observeTarget);
    expect(controller.bouncingToy, isNull);
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

class _RecordingRuntime implements PetBehaviorRuntime {
  final calls = <PetActionPlan>[];
  final targets = <PetInteractable>[];

  @override
  void startAction(PetActionPlan plan, PetInteractable target) {
    calls.add(plan);
    targets.add(target);
  }
}

class _UnboundedTarget implements PetInteractable {
  const _UnboundedTarget();

  @override
  Rect get bounds => const Rect.fromLTWH(0, 0, 10, 10);

  @override
  String get id => 'invalid';

  @override
  WorldObjectKind get kind => WorldObjectKind.platform;

  @override
  Offset get position => Offset.zero;

  @override
  PetState interactionFor(PetEvent event) => PetState.jump;
}

PetNormalizedContentKind _contentKindFor(WorldObjectKind kind) =>
    switch (kind) {
      WorldObjectKind.platform => PetNormalizedContentKind.text,
      WorldObjectKind.emojiToy => PetNormalizedContentKind.emoji,
      WorldObjectKind.animatedToy => PetNormalizedContentKind.gif,
    };

({
  WorldObjectKind targetKind,
  PetStimulusType stimulus,
  PetRuntimeAction? runtimeAction,
  PetBehaviorExecutionStatus status,
  bool walkToward,
  bool carriesPayload,
  String reason,
})
_expectationFor(PetBehaviorAction action) => switch (action) {
  PetBehaviorAction.nosePawBump => (
    targetKind: WorldObjectKind.platform,
    stimulus: PetStimulusType.userTap,
    runtimeAction: PetRuntimeAction.jumpToPlatform,
    status: PetBehaviorExecutionStatus.executed,
    walkToward: false,
    carriesPayload: false,
    reason: 'platform jump',
  ),
  PetBehaviorAction.headBuntRub || PetBehaviorAction.beakTouch => (
    targetKind: WorldObjectKind.platform,
    stimulus: PetStimulusType.userTap,
    runtimeAction: PetRuntimeAction.jumpToPlatform,
    status: PetBehaviorExecutionStatus.fallback,
    walkToward: false,
    carriesPayload: false,
    reason: 'platform jump fallback',
  ),
  PetBehaviorAction.runChase || PetBehaviorAction.pounce => (
    targetKind: WorldObjectKind.emojiToy,
    stimulus: PetStimulusType.emoji,
    runtimeAction: PetRuntimeAction.chaseEmoji,
    status: PetBehaviorExecutionStatus.executed,
    walkToward: false,
    carriesPayload: true,
    reason: 'emoji chase',
  ),
  PetBehaviorAction.flyFlap || PetBehaviorAction.batPounce => (
    targetKind: WorldObjectKind.emojiToy,
    stimulus: PetStimulusType.emoji,
    runtimeAction: PetRuntimeAction.chaseEmoji,
    status: PetBehaviorExecutionStatus.fallback,
    walkToward: false,
    carriesPayload: true,
    reason: 'emoji chase fallback',
  ),
  PetBehaviorAction.sniffBubble => (
    targetKind: WorldObjectKind.animatedToy,
    stimulus: PetStimulusType.gif,
    runtimeAction: PetRuntimeAction.inspectMedia,
    status: PetBehaviorExecutionStatus.fallback,
    walkToward: false,
    carriesPayload: true,
    reason: 'observe fallback',
  ),
  PetBehaviorAction.headTiltFocus ||
  PetBehaviorAction.sniffWhiskerScan ||
  PetBehaviorAction.headTiltEyeFocus => (
    targetKind: WorldObjectKind.animatedToy,
    stimulus: PetStimulusType.gif,
    runtimeAction: PetRuntimeAction.inspectMedia,
    status: PetBehaviorExecutionStatus.fallback,
    walkToward: false,
    carriesPayload: true,
    reason: 'observe fallback',
  ),
  PetBehaviorAction.novelObjectNoseProbe => (
    targetKind: WorldObjectKind.animatedToy,
    stimulus: PetStimulusType.newMessageBubble,
    runtimeAction: PetRuntimeAction.dogProbe,
    status: PetBehaviorExecutionStatus.executed,
    walkToward: false,
    carriesPayload: false,
    reason: 'native dog media probe',
  ),
  PetBehaviorAction.pawTest => (
    targetKind: WorldObjectKind.animatedToy,
    stimulus: PetStimulusType.newMessageBubble,
    runtimeAction: PetRuntimeAction.catPawTest,
    status: PetBehaviorExecutionStatus.executed,
    walkToward: false,
    carriesPayload: false,
    reason: 'native paw test',
  ),
  PetBehaviorAction.beakProbe => (
    targetKind: WorldObjectKind.animatedToy,
    stimulus: PetStimulusType.newMessageBubble,
    runtimeAction: PetRuntimeAction.parrotProbe,
    status: PetBehaviorExecutionStatus.executed,
    walkToward: false,
    carriesPayload: false,
    reason: 'native parrot media probe',
  ),
  PetBehaviorAction.circleSniff => (
    targetKind: WorldObjectKind.platform,
    stimulus: PetStimulusType.newMessageBubble,
    runtimeAction: PetRuntimeAction.observeTarget,
    status: PetBehaviorExecutionStatus.fallback,
    walkToward: true,
    carriesPayload: false,
    reason: 'walk-toward observe fallback',
  ),
  PetBehaviorAction.approachArc ||
  PetBehaviorAction.approachStopStart ||
  PetBehaviorAction.approachLowSilent ||
  PetBehaviorAction.approachSideways => (
    targetKind: WorldObjectKind.platform,
    stimulus: PetStimulusType.newMessageBubble,
    runtimeAction: PetRuntimeAction.observeTarget,
    status: PetBehaviorExecutionStatus.fallback,
    walkToward: true,
    carriesPayload: false,
    reason: 'light approach fallback',
  ),
  PetBehaviorAction.hidePeek || PetBehaviorAction.beakManipulate => (
    targetKind: WorldObjectKind.platform,
    stimulus: PetStimulusType.newMessageBubble,
    runtimeAction: PetRuntimeAction.observeTarget,
    status: PetBehaviorExecutionStatus.fallback,
    walkToward: false,
    carriesPayload: false,
    reason: 'observe fallback; no equivalent runtime',
  ),
  PetBehaviorAction.flyBack => (
    targetKind: WorldObjectKind.platform,
    stimulus: PetStimulusType.userTap,
    runtimeAction: null,
    status: PetBehaviorExecutionStatus.ignored,
    walkToward: false,
    carriesPayload: false,
    reason: 'flyBack has no safe runtime mapping',
  ),
  _ => (
    targetKind: WorldObjectKind.platform,
    stimulus: PetStimulusType.userTap,
    runtimeAction: null,
    status: PetBehaviorExecutionStatus.ignored,
    walkToward: false,
    carriesPayload: false,
    reason: 'unsupported action ${action.name}',
  ),
};

PetBehaviorSelection _selection(
  PetBehaviorAction action,
  PetBehaviorCapability capability, {
  String targetId = 'target',
  PetStimulusType stimulusType = PetStimulusType.userTap,
}) => PetBehaviorSelection(
  action: action,
  stimulusType: stimulusType,
  targetId: targetId,
  capability: capability,
  reason: 'test:$action',
);

PetMessageTarget _target({
  String id = 'target',
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
