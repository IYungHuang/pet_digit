import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/pet/domain/pet_behavior_runtime.dart';
import 'package:chat_pet_mvp/pet/domain/pet_effects.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_content_kind.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_target.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world_controller.dart';

void main() {
  test(
    'jump completion retains the landed target and migrates it canonically',
    () {
      const source = (roomId: 'room', clientId: 'client');
      final controller = PetWorldController();
      final clientTarget = _target(id: 'client', sourceIdentity: source);
      controller.objects = [clientTarget];

      controller.startJumpToPlatform(clientTarget);
      controller.tick(const Duration(milliseconds: 550));

      expect(controller.currentAction, PetActionType.none);
      expect(controller.state, PetState.idle);
      expect(controller.activeTarget, same(clientTarget));
      expect(controller.activePayload, isNull);
      expect(controller.currentPlatform, same(clientTarget));
      expect(controller.getBubbleDeflection('client'), 0.0);
      expect(controller.springNotifier.value, 1);
      expect(
        controller.particles.where(
          (particle) => particle.kind == ParticleKind.dust,
        ),
        hasLength(2),
      );

      controller.tick(const Duration(milliseconds: 1));
      expect(
        controller.getBubbleDeflection('client'),
        closeTo(0.15648, 0.000001),
      );
      expect(controller.springNotifier.value, 2);

      final serverTarget = _target(id: 'server', sourceIdentity: source);
      controller.setMessageTargets([serverTarget]);

      expect(serverTarget.bounds, const Rect.fromLTWH(100, 200, 180, 52));
      expect(controller.activeTarget, same(serverTarget));
      expect(controller.currentPlatform, same(serverTarget));
      expect(controller.getBubbleDeflection('client'), 0.0);
      expect(
        controller.getBubbleDeflection('server'),
        closeTo(0.15648, 0.000001),
      );
    },
  );

  test('replacement releases a landed platform with chase impulse 70', () {
    final controller = PetWorldController();
    final platform = _target(id: 'platform');

    controller.startJumpToPlatform(platform);
    controller.tick(const Duration(milliseconds: 550));
    controller.tick(const Duration(seconds: 2));
    expect(controller.getBubbleDeflection(platform.id), 0.0);
    controller.startChaseEmoji(_target(id: 'emoji'), payload: '🎾');

    expect(controller.currentPlatform, isNull);
    controller.tick(const Duration(milliseconds: 1));
    expect(
      controller.getBubbleDeflection(platform.id),
      closeTo(0.06846, 0.000001),
    );
  });

  for (final replacement
      in <
        ({
          String name,
          void Function(PetWorldController, PetMessageTarget) start,
        })
      >[
        (
          name: 'jump',
          start: (controller, target) => controller.startJumpToPlatform(target),
        ),
        (
          name: 'inspect',
          start: (controller, target) =>
              controller.startInspectGif(target, payload: 'media'),
        ),
        (
          name: 'paw',
          start: (controller, target) => controller.startPawTest(target),
        ),
        (
          name: 'dog probe',
          start: (controller, target) => controller.startDogProbe(target),
        ),
        (
          name: 'parrot probe',
          start: (controller, target) => controller.startParrotProbe(target),
        ),
        (
          name: 'observe',
          start: (controller, target) =>
              controller.startObserveTarget(target, walkToward: false),
        ),
      ]) {
    test(
      'replacement releases a landed platform with ${replacement.name} impulse 60',
      () {
        final controller = PetWorldController();
        final platform = _target(id: 'platform');

        controller.startJumpToPlatform(platform);
        controller.tick(const Duration(milliseconds: 550));
        controller.tick(const Duration(seconds: 2));
        expect(controller.getBubbleDeflection(platform.id), 0.0);
        replacement.start(controller, _target(id: 'replacement'));

        expect(controller.currentPlatform, isNull);
        controller.tick(const Duration(milliseconds: 1));
        expect(
          controller.getBubbleDeflection(platform.id),
          closeTo(0.05868, 0.000001),
        );
      },
    );
  }

  test(
    'mid-jump replacement drops airborne effects and resets replacement timing',
    () {
      final controller = PetWorldController();
      final platform = _target(id: 'platform');
      final media = _target(id: 'media');
      final payload = <String, Object>{'media': 'gif-mid-jump'};

      controller.startJumpToPlatform(platform);
      controller.tick(const Duration(milliseconds: 200));
      expect(controller.currentAction, PetActionType.jumpToPlatform);
      expect(controller.state, PetState.jump);

      controller.startInspectGif(media, payload: payload);

      expect(controller.currentAction, PetActionType.inspectGif);
      expect(controller.activeTarget, same(media));
      expect(controller.activePayload, same(payload));
      expect(controller.currentPlatform, isNull);
      expect(controller.particles, isEmpty);
      expect(controller.getBubbleDeflection(platform.id), 0.0);
      controller.tick(const Duration(milliseconds: 2799));
      expect(controller.currentAction, PetActionType.inspectGif);
      controller.tick(const Duration(milliseconds: 1));
      expect(controller.currentAction, PetActionType.none);
    },
  );

  test(
    'mid-chase replacement clears toy while preserving released platform effect',
    () {
      final controller = PetWorldController();
      final platform = _target(id: 'platform');
      final chaseTarget = _target(id: 'emoji');
      final media = _target(id: 'media');
      final chasePayload = <String, Object>{'emoji': '🎾'};
      final mediaPayload = <String, Object>{'media': 'gif-mid-chase'};

      controller.startJumpToPlatform(platform);
      controller.tick(const Duration(milliseconds: 550));
      controller.tick(const Duration(seconds: 2));
      controller.startChaseEmoji(chaseTarget, payload: chasePayload);
      controller.tick(const Duration(milliseconds: 101));
      final releasedPlatformDeflection = controller.getBubbleDeflection(
        platform.id,
      );
      final notificationsBeforeReplacement = controller.springNotifier.value;

      expect(controller.currentAction, PetActionType.chaseEmoji);
      expect(controller.activeTarget, same(chaseTarget));
      expect(controller.activePayload, same(chasePayload));
      expect(controller.currentPlatform, isNull);
      expect(controller.bouncingToy, isNotNull);

      controller.startInspectGif(media, payload: mediaPayload);

      expect(controller.currentAction, PetActionType.inspectGif);
      expect(controller.activeTarget, same(media));
      expect(controller.activePayload, same(mediaPayload));
      expect(controller.currentPlatform, isNull);
      expect(controller.bouncingToy, isNull);
      expect(
        controller.getBubbleDeflection(platform.id),
        releasedPlatformDeflection,
      );
      expect(controller.springNotifier.value, notificationsBeforeReplacement);
      controller.tick(const Duration(milliseconds: 2799));
      expect(controller.currentAction, PetActionType.inspectGif);
      controller.tick(const Duration(milliseconds: 1));
      expect(controller.currentAction, PetActionType.none);
    },
  );

  test(
    'unmeasured pending target follows canonical reconciliation and removal',
    () {
      const source = (roomId: 'room', clientId: 'client');
      final controller = PetWorldController();
      final clientTarget = _unmeasuredTarget(
        id: 'client',
        sourceIdentity: source,
      );
      controller.setMessageTargets([clientTarget]);

      expect(
        controller.interact(clientTarget.id).status,
        PetBehaviorExecutionStatus.ignored,
      );
      expect(controller.currentAction, PetActionType.none);
      expect(controller.activeTarget, isNull);

      final serverTarget = _unmeasuredTarget(
        id: 'server',
        sourceIdentity: source,
      );
      controller.setMessageTargets([serverTarget]);
      controller.updateObjectBounds({
        serverTarget.id: const Rect.fromLTWH(100, 200, 180, 52),
      });

      expect(controller.currentAction, PetActionType.jumpToPlatform);
      expect(controller.activeTarget, same(serverTarget));
      controller.setMessageTargets([]);

      expect(controller.currentAction, PetActionType.none);
      expect(controller.state, PetState.idle);
      expect(controller.activeTarget, isNull);
      expect(controller.activePayload, isNull);
      expect(controller.currentPlatform, isNull);
      expect(controller.bouncingToy, isNull);
    },
  );

  final inspectionPayload = <String, Object>{'media': 'gif-1'};
  for (final completion
      in <
        ({
          String name,
          PetActionType action,
          Duration duration,
          Object? payload,
          bool clearsTarget,
          void Function(PetWorldController, PetMessageTarget) start,
        })
      >[
        (
          name: 'chase',
          action: PetActionType.chaseEmoji,
          duration: const Duration(seconds: 4),
          payload: '🎾',
          clearsTarget: false,
          start: (controller, target) =>
              controller.startChaseEmoji(target, payload: '🎾'),
        ),
        (
          name: 'inspect',
          action: PetActionType.inspectGif,
          duration: const Duration(milliseconds: 2800),
          payload: inspectionPayload,
          clearsTarget: false,
          start: (controller, target) =>
              controller.startInspectGif(target, payload: inspectionPayload),
        ),
        (
          name: 'paw test',
          action: PetActionType.pawTest,
          duration: const Duration(milliseconds: 3000),
          payload: null,
          clearsTarget: false,
          start: (controller, target) => controller.startPawTest(target),
        ),
        (
          name: 'dog probe',
          action: PetActionType.dogProbe,
          duration: const Duration(milliseconds: 2800),
          payload: null,
          clearsTarget: false,
          start: (controller, target) => controller.startDogProbe(target),
        ),
        (
          name: 'parrot probe',
          action: PetActionType.parrotProbe,
          duration: const Duration(milliseconds: 2700),
          payload: null,
          clearsTarget: false,
          start: (controller, target) => controller.startParrotProbe(target),
        ),
        (
          name: 'stationary observe',
          action: PetActionType.observeTarget,
          duration: const Duration(milliseconds: 900),
          payload: null,
          clearsTarget: true,
          start: (controller, target) =>
              controller.startObserveTarget(target, walkToward: false),
        ),
      ]) {
    test(
      '${completion.name} natural completion retains its historical facade state',
      () {
        final controller = PetWorldController();
        final target = _target();

        completion.start(controller, target);
        expect(controller.currentAction, completion.action);
        controller.tick(completion.duration);

        expect(controller.currentAction, PetActionType.none);
        expect(controller.state, PetState.idle);
        expect(
          controller.activeTarget,
          completion.clearsTarget ? isNull : same(target),
        );
        expect(controller.activePayload, same(completion.payload));
      },
    );
  }

  test(
    'chase preserves target and payload through early toy expiry before cleanup',
    () {
      final controller = PetWorldController();
      final target = _target(id: 'emoji');
      final payload = <String, Object>{'emoji': '🎾'};

      controller.startChaseEmoji(target, payload: payload);
      controller.tick(const Duration(seconds: 4));

      expect(controller.currentAction, PetActionType.none);
      expect(controller.state, PetState.idle);
      expect(controller.bouncingToy, isNull);
      expect(controller.activeTarget, same(target));
      expect(controller.activePayload, same(payload));

      final replacement = _target(id: 'media');
      final replacementPayload = <String, Object>{'media': 'gif-2'};
      controller.startInspectGif(replacement, payload: replacementPayload);
      expect(controller.activeTarget, same(replacement));
      expect(controller.activePayload, same(replacementPayload));

      controller.setPet(PetType.cat);
      expect(controller.currentAction, PetActionType.none);
      expect(controller.activeTarget, isNull);
      expect(controller.activePayload, isNull);
      expect(controller.bouncingToy, isNull);
    },
  );

  test(
    'chase caught toy completes only after its 0.4 second expiry boundary',
    () {
      final controller = PetWorldController();
      final target = _target(id: 'emoji');
      final payload = <String, Object>{'emoji': '🪀'};

      controller.startChaseEmoji(target, payload: payload);
      controller.bouncingToy!.isCaught = true;
      controller.tick(const Duration(milliseconds: 400));

      expect(controller.currentAction, PetActionType.chaseEmoji);
      expect(controller.bouncingToy, isNotNull);
      controller.tick(const Duration(milliseconds: 1));

      expect(controller.currentAction, PetActionType.none);
      expect(controller.state, PetState.idle);
      expect(controller.bouncingToy, isNull);
      expect(controller.activeTarget, same(target));
      expect(controller.activePayload, same(payload));

      final replacement = _target(id: 'media');
      final replacementPayload = <String, Object>{'media': 'gif-caught'};
      controller.startInspectGif(replacement, payload: replacementPayload);
      expect(controller.activeTarget, same(replacement));
      expect(controller.activePayload, same(replacementPayload));

      controller.setPet(PetType.cat);
      expect(controller.currentAction, PetActionType.none);
      expect(controller.activeTarget, isNull);
      expect(controller.activePayload, isNull);
      expect(controller.bouncingToy, isNull);
    },
  );

  test('ordinary chase remains active immediately before toy expiry', () {
    final controller = PetWorldController();
    final target = _target(id: 'emoji');
    final payload = <String, Object>{'emoji': '🎾'};

    controller.startChaseEmoji(target, payload: payload);
    controller.tick(const Duration(milliseconds: 3500));

    expect(controller.currentAction, PetActionType.chaseEmoji);
    expect(controller.bouncingToy, isNotNull);
    expect(controller.activeTarget, same(target));
    expect(controller.activePayload, same(payload));
    controller.tick(const Duration(milliseconds: 1));

    expect(controller.currentAction, PetActionType.none);
    expect(controller.state, PetState.idle);
    expect(controller.bouncingToy, isNull);
    expect(controller.activeTarget, same(target));
    expect(controller.activePayload, same(payload));
  });

  test(
    'inspection remains active immediately before its 2.8 second boundary',
    () {
      final controller = PetWorldController();
      final target = _target(id: 'media');
      final payload = <String, Object>{'media': 'gif-boundary'};

      controller.startInspectGif(target, payload: payload);
      controller.tick(const Duration(milliseconds: 2799));

      expect(controller.currentAction, PetActionType.inspectGif);
      expect(controller.activeTarget, same(target));
      expect(controller.activePayload, same(payload));
      controller.tick(const Duration(milliseconds: 1));

      expect(controller.currentAction, PetActionType.none);
      expect(controller.state, PetState.idle);
      expect(controller.activeTarget, same(target));
      expect(controller.activePayload, same(payload));
    },
  );

  test(
    'inspection retains media payload at 2.8 seconds until replacement and reset',
    () {
      final controller = PetWorldController();
      final target = _target(id: 'media');
      final payload = <String, Object>{'media': 'gif-3'};

      controller.startInspectGif(target, payload: payload);
      controller.tick(const Duration(milliseconds: 2800));

      expect(controller.currentAction, PetActionType.none);
      expect(controller.state, PetState.idle);
      expect(controller.activeTarget, same(target));
      expect(controller.activePayload, same(payload));

      final replacement = _target(id: 'paw');
      controller.startPawTest(replacement);
      expect(controller.activeTarget, same(replacement));
      expect(controller.activePayload, isNull);

      controller.setPet(PetType.parrot);
      expect(controller.currentAction, PetActionType.none);
      expect(controller.activeTarget, isNull);
      expect(controller.activePayload, isNull);
    },
  );

  test(
    'first patrol tick records reset asymmetries after every natural completion',
    () {
      final completions =
          <
            ({
              String name,
              Duration duration,
              PetState patrolState,
              void Function(PetWorldController, PetMessageTarget) start,
            })
          >[
            (
              name: 'jump',
              duration: const Duration(milliseconds: 550),
              patrolState: PetState.idle,
              start: (controller, target) =>
                  controller.startJumpToPlatform(target),
            ),
            (
              name: 'chase',
              duration: const Duration(seconds: 4),
              patrolState: PetState.idle,
              start: (controller, target) =>
                  controller.startChaseEmoji(target, payload: '🎾'),
            ),
            (
              name: 'inspect',
              duration: const Duration(milliseconds: 2800),
              patrolState: PetState.idle,
              start: (controller, target) =>
                  controller.startInspectGif(target, payload: 'media'),
            ),
            (
              name: 'paw test',
              duration: const Duration(milliseconds: 3000),
              patrolState: PetState.idle,
              start: (controller, target) => controller.startPawTest(target),
            ),
            (
              name: 'dog probe',
              duration: const Duration(milliseconds: 2800),
              patrolState: PetState.walk,
              start: (controller, target) => controller.startDogProbe(target),
            ),
            (
              name: 'parrot probe',
              duration: const Duration(milliseconds: 2700),
              patrolState: PetState.walk,
              start: (controller, target) =>
                  controller.startParrotProbe(target),
            ),
            (
              name: 'stationary observe',
              duration: const Duration(milliseconds: 900),
              patrolState: PetState.walk,
              start: (controller, target) =>
                  controller.startObserveTarget(target, walkToward: false),
            ),
          ];

      for (final completion in completions) {
        final controller = PetWorldController();
        final target = _target(id: completion.name);
        completion.start(controller, target);
        controller.tick(completion.duration);

        expect(
          controller.currentAction,
          PetActionType.none,
          reason: completion.name,
        );
        controller.tick(const Duration(milliseconds: 601));
        expect(
          controller.state,
          completion.patrolState,
          reason: completion.name,
        );
      }
    },
  );

  test(
    'observe approach resets its action clock before the 0.9 second observation phase',
    () {
      final controller = PetWorldController();
      final target = _target();

      controller.startObserveTarget(target, walkToward: true);
      controller.tick(const Duration(seconds: 10));

      expect(controller.currentAction, PetActionType.observeTarget);
      expect(controller.state, PetState.observe);
      controller.tick(const Duration(milliseconds: 899));
      expect(controller.currentAction, PetActionType.observeTarget);
      controller.tick(const Duration(milliseconds: 1));
      expect(controller.currentAction, PetActionType.none);
      expect(controller.state, PetState.idle);
      expect(controller.activeTarget, isNull);
      expect(controller.activePayload, isNull);
      controller.tick(const Duration(milliseconds: 601));
      expect(controller.state, PetState.walk);
    },
  );

  test(
    'nonpositive ticks do not advance an action and exact phase boundaries advance once',
    () {
      final controller = PetWorldController();
      final target = _target();
      final initialPosition = controller.position;

      controller.startInspectGif(target, payload: 'media');
      controller.tick(Duration.zero);
      controller.tick(const Duration(milliseconds: -1));

      expect(controller.currentAction, PetActionType.inspectGif);
      expect(controller.position, initialPosition);
      controller.tick(const Duration(milliseconds: 600));
      expect(controller.state, PetState.observe);
      controller.tick(const Duration(milliseconds: 600));
      expect(controller.state, PetState.run);
    },
  );

  test('paw impacts occur in order at their two timeline boundaries', () {
    final controller = PetWorldController();
    final target = _target();

    controller.startPawTest(target);
    controller.tick(const Duration(milliseconds: 1999));

    expect(controller.currentAction, PetActionType.pawTest);
    expect(controller.getBubbleDeflection(target.id), 0.0);
    expect(controller.springNotifier.value, 0);
    controller.tick(const Duration(milliseconds: 1));
    expect(controller.springNotifier.value, 1);
    expect(controller.getBubbleDeflection(target.id), 0.0);
    controller.tick(const Duration(milliseconds: 1));
    expect(
      controller.getBubbleDeflection(target.id),
      closeTo(0.04401, 0.000001),
    );
    expect(controller.springNotifier.value, 2);

    controller.tick(const Duration(milliseconds: 449));
    expect(controller.springNotifier.value, 4);
    expect(controller.getBubbleDeflection(target.id), 0.0);
    controller.tick(const Duration(milliseconds: 1));
    expect(
      controller.getBubbleDeflection(target.id),
      closeTo(0.031296, 0.000001),
    );
  });

  test('one large paw tick emits both impacts and completes normally', () {
    final controller = PetWorldController();
    final target = _target();

    controller.startPawTest(target);
    controller.tick(const Duration(milliseconds: 3000));

    expect(controller.springNotifier.value, 2);
    expect(controller.getBubbleDeflection(target.id), 0.0);
    expect(controller.currentAction, PetActionType.none);
    expect(controller.state, PetState.idle);
    expect(controller.activeTarget, same(target));
    expect(controller.activePayload, isNull);
    controller.tick(const Duration(milliseconds: 1));
    expect(controller.springNotifier.value, 3);
    expect(
      controller.getBubbleDeflection(target.id),
      closeTo(0.075306, 0.000001),
    );
    controller.tick(const Duration(milliseconds: 600));
    expect(controller.state, PetState.idle);
  });

  test(
    'geometry changes retarget a jump and removal clears its landed runtime',
    () {
      final controller = PetWorldController();
      final target = _target(id: 'platform');
      controller.objects = [target];

      controller.startJumpToPlatform(target);
      controller.tick(const Duration(milliseconds: 200));
      controller.updateObjectBounds({
        target.id: const Rect.fromLTWH(120, 300, 180, 52),
      });
      controller.tick(const Duration(milliseconds: 400));

      expect(controller.currentAction, PetActionType.none);
      expect(controller.currentPlatform, same(target));
      expect(controller.position, const Offset(178, 248));

      controller.setMessageTargets([]);
      expect(controller.currentAction, PetActionType.none);
      expect(controller.state, PetState.idle);
      expect(controller.activeTarget, isNull);
      expect(controller.currentPlatform, isNull);
    },
  );
}

PetMessageTarget _target({
  String id = 'target',
  WorldObjectKind kind = WorldObjectKind.platform,
  Object? payload = 'payload',
  ({String roomId, String clientId})? sourceIdentity,
}) {
  return PetMessageTarget(
    id: id,
    kind: kind,
    contentKind: PetNormalizedContentKind.text,
    payload: payload,
    messageText: '$payload',
    sourceIdentity: sourceIdentity,
  )..markMeasuredBounds(const Rect.fromLTWH(100, 200, 180, 52));
}

PetMessageTarget _unmeasuredTarget({
  required String id,
  required ({String roomId, String clientId}) sourceIdentity,
}) {
  return PetMessageTarget(
    id: id,
    kind: WorldObjectKind.platform,
    contentKind: PetNormalizedContentKind.text,
    payload: 'hello',
    messageText: 'hello',
    sourceIdentity: sourceIdentity,
  );
}
