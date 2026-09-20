import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/pet/domain/actions/cat_paw_test_action.dart';
import 'package:chat_pet_mvp/pet/domain/actions/chase_emoji_action.dart';
import 'package:chat_pet_mvp/pet/domain/actions/dog_probe_action.dart';
import 'package:chat_pet_mvp/pet/domain/actions/inspect_media_action.dart';
import 'package:chat_pet_mvp/pet/domain/actions/jump_to_platform_action.dart';
import 'package:chat_pet_mvp/pet/domain/actions/observe_target_action.dart';
import 'package:chat_pet_mvp/pet/domain/actions/parrot_probe_action.dart';
import 'package:chat_pet_mvp/pet/domain/actions/pet_action_context.dart';
import 'package:chat_pet_mvp/pet/domain/actions/pet_action_handler.dart';
import 'package:chat_pet_mvp/pet/domain/pet_action_plan.dart';
import 'package:chat_pet_mvp/pet/domain/pet_action_runner.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_catalog.dart';
import 'package:chat_pet_mvp/pet/domain/pet_effects.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_content_kind.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_target.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';

void main() {
  group('PetActionRunner handler registry', () {
    test('default registry creates fresh handlers for every action', () {
      final runner = PetActionRunner();
      for (final action in PetRuntimeAction.values) {
        final first = runner.createHandler(action);
        final second = runner.createHandler(action);
        expect((first.action, second.action), (action, action));
        expect(second, isNot(same(first)), reason: action.name);
      }
    });

    test('rejects missing and duplicate factories', () {
      final complete = PetRuntimeAction.values
          .map((a) => MapEntry(a, () => _StubHandler(a)))
          .toList();
      expect(
        () => PetActionRunner(handlerFactories: complete.skip(1)),
        throwsArgumentError,
      );
      expect(
        () => PetActionRunner(handlerFactories: [...complete, complete.first]),
        throwsArgumentError,
      );
    });
  });

  group('ObserveTargetAction', () {
    test('start, arrival phase reset, frame, and completion', () {
      final c = _context(position: const Offset(20, 200));
      final h = ObserveTargetAction()
        ..start(c, _plan(PetRuntimeAction.observeTarget, walk: true));
      expect((c.state, c.frame), (PetState.walk, 0));
      c.position = const Offset(36, 188);
      c.advance(100);
      expect(
        h.tick(c, const Duration(milliseconds: 100)),
        PetActionTickResult.running,
      );
      expect(
        (c.state, c.frame, c.phaseElapsed),
        (PetState.observe, 0, Duration.zero),
      );
      expect(c.previousPhaseElapsed, Duration.zero);
      c.advance(900);
      expect(
        h.tick(c, const Duration(milliseconds: 900)),
        PetActionTickResult.complete,
      );
      expect(
        (c.state, c.completed),
        (PetState.idle, PetActionEndReason.completed),
      );
    });

    test('stationary key frame and cancel contract', () {
      final c = _context();
      final h = ObserveTargetAction()
        ..start(c, _plan(PetRuntimeAction.observeTarget));
      c.advance(350);
      expect(
        h.tick(c, const Duration(milliseconds: 350)),
        PetActionTickResult.running,
      );
      expect(c.frame, 1);
      _expectCancelStable(h, c);
    });
  });

  group('CatPawTestAction', () {
    test('start and large tick use live target for ordered effects', () {
      final c = _context();
      final h = CatPawTestAction()
        ..start(c, _plan(PetRuntimeAction.catPawTest));
      expect((c.state, c.frame), (PetState.catStalk, 0));
      c.target = _target('replacement', left: 210);
      c.advance(2500);
      expect(
        h.tick(c, const Duration(milliseconds: 2500)),
        PetActionTickResult.running,
      );
      expect(c.effects, [
        'impulse:replacement:45.0',
        'impulse:replacement:32.0',
      ]);
      expect((c.state, c.frame), (PetState.pawTest, 5));
    });

    test('completion and cancel contract', () {
      final c = _context();
      final h = CatPawTestAction()
        ..start(c, _plan(PetRuntimeAction.catPawTest));
      _expectCancelStable(h, c);
      c.advance(3000);
      expect(
        h.tick(c, const Duration(milliseconds: 3000)),
        PetActionTickResult.complete,
      );
      expect(
        (c.state, c.frame, c.patrolResets, c.completed),
        (PetState.idle, 5, 1, PetActionEndReason.completed),
      );
    });
  });

  group('DogProbeAction', () {
    test('start and large tick use live target for ordered effects', () {
      final c = _context();
      final h = DogProbeAction()..start(c, _plan(PetRuntimeAction.dogProbe));
      expect((c.state, c.frame), (PetState.dogProbe, 0));
      c.target = _target('replacement', left: 210);
      c.advance(2400);
      expect(
        h.tick(c, const Duration(milliseconds: 2400)),
        PetActionTickResult.running,
      );
      expect(c.effects, [
        'impulse:replacement:24.0',
        'impulse:replacement:18.0',
      ]);
      expect(c.frame, 5);
    });

    test('completion and cancel contract', () {
      final c = _context();
      final h = DogProbeAction()..start(c, _plan(PetRuntimeAction.dogProbe));
      _expectCancelStable(h, c);
      c.advance(2800);
      expect(
        h.tick(c, const Duration(milliseconds: 2800)),
        PetActionTickResult.complete,
      );
      expect(
        (c.state, c.frame, c.patrolResets, c.completed),
        (PetState.idle, 5, 0, PetActionEndReason.completed),
      );
    });
  });

  group('ParrotProbeAction', () {
    test('start and large tick use live target for ordered effects', () {
      final c = _context();
      final h = ParrotProbeAction()
        ..start(c, _plan(PetRuntimeAction.parrotProbe));
      expect((c.state, c.frame), (PetState.parrotProbe, 0));
      c.target = _target('replacement', left: 210);
      c.advance(2400);
      expect(
        h.tick(c, const Duration(milliseconds: 2400)),
        PetActionTickResult.running,
      );
      expect(c.effects, [
        'impulse:replacement:20.0',
        'impulse:replacement:14.0',
      ]);
      expect(c.frame, 5);
    });

    test('completion and cancel contract', () {
      final c = _context();
      final h = ParrotProbeAction()
        ..start(c, _plan(PetRuntimeAction.parrotProbe));
      _expectCancelStable(h, c);
      c.advance(2700);
      expect(
        h.tick(c, const Duration(milliseconds: 2700)),
        PetActionTickResult.complete,
      );
      expect(
        (c.state, c.frame, c.patrolResets, c.completed),
        (PetState.idle, 5, 0, PetActionEndReason.completed),
      );
    });
  });

  group('InspectMediaAction', () {
    test('start and run boundary publish frame and footsteps', () {
      final c = _context();
      final h = InspectMediaAction()
        ..start(c, _plan(PetRuntimeAction.inspectMedia));
      expect((c.state, c.frame), (PetState.observe, 0));
      c.advance(1200);
      expect(
        h.tick(c, const Duration(milliseconds: 1200)),
        PetActionTickResult.running,
      );
      expect((c.state, c.frame), (PetState.run, 0));
      expect(c.effects, contains('footsteps:1200:true'));
    });

    test('completion and cancel contract', () {
      final c = _context();
      final h = InspectMediaAction()
        ..start(c, _plan(PetRuntimeAction.inspectMedia));
      _expectCancelStable(h, c);
      c.advance(2800);
      expect(
        h.tick(c, const Duration(milliseconds: 2800)),
        PetActionTickResult.complete,
      );
      expect(
        (c.state, c.patrolResets, c.completed),
        (PetState.idle, 1, PetActionEndReason.completed),
      );
    });
  });

  group('ChaseEmojiAction', () {
    test('start and expired toy path complete with published frame', () {
      final c = _context();
      final h = ChaseEmojiAction()
        ..start(c, _plan(PetRuntimeAction.chaseEmoji, payload: '🎾'));
      expect((c.state, c.frame, c.toy?.emoji), (PetState.pounce, 0, '🎾'));
      _expectCancelStable(h, c);
      c.toy!.lifetime = 3.6;
      c.advance(16);
      expect(
        h.tick(c, const Duration(milliseconds: 16)),
        PetActionTickResult.complete,
      );
      expect(
        (c.state, c.patrolResets, c.completed),
        (PetState.idle, 1, PetActionEndReason.completed),
      );
    });

    test('caught path removes toy after 1200ms', () {
      final c = _context();
      final h = ChaseEmojiAction()
        ..start(c, _plan(PetRuntimeAction.chaseEmoji));
      final toy = c.toy!;
      c.position = Offset(
        toy.position.dx - 32 * toy.direction,
        toy.position.dy - 44,
      );
      c.advance(1300);
      expect(
        h.tick(c, const Duration(milliseconds: 1300)),
        PetActionTickResult.complete,
      );
      expect(
        (c.state, c.frame, toy.isCaught, c.toy, c.completed),
        (PetState.idle, 1, true, null, PetActionEndReason.completed),
      );
    });
  });

  group('JumpToPlatformAction', () {
    test('start and midpoint publish surface, height, and frame', () {
      final c = _context(position: const Offset(20, 300));
      final h = JumpToPlatformAction()
        ..start(c, _plan(PetRuntimeAction.jumpToPlatform));
      expect(
        (c.state, c.frame, c.currentSurfaceY, c.heightAboveSurface),
        (PetState.jump, 0, 352.0, 0.0),
      );
      _expectCancelStable(h, c);
      c.advance(275);
      expect(
        h.tick(c, const Duration(milliseconds: 275)),
        PetActionTickResult.running,
      );
      expect(c.heightAboveSurface, greaterThan(0));
      expect(c.currentSurfaceY, closeTo(276, .001));
      expect(c.frame, 1);
    });

    test('landing uses live target and publishes ordered effects', () {
      final c = _context(position: const Offset(20, 300));
      final h = JumpToPlatformAction()
        ..start(c, _plan(PetRuntimeAction.jumpToPlatform));
      final replacement = _target('replacement', left: 210, top: 180);
      c.target = replacement;
      c.deflections['replacement'] = 3;
      c.advance(550);
      expect(
        h.tick(c, const Duration(milliseconds: 550)),
        PetActionTickResult.complete,
      );
      expect(c.currentPlatform, same(replacement));
      expect(
        (c.position.dy, c.heightAboveSurface, c.state, c.completed),
        (131.0, 0.0, PetState.idle, PetActionEndReason.completed),
      );
      expect(c.effects, [
        'impulse:replacement:160.0',
        'dust:244.0,183.0',
        'dust:268.0,183.0',
      ]);
    });
  });
}

void _expectCancelStable(PetActionHandler handler, _FakeContext c) {
  final state = c.state;
  final frame = c.frame;
  final effects = List<String>.of(c.effects);
  final toy = c.toy;
  handler.cancel(c, PetActionEndReason.replaced);
  expect(c.state, state);
  expect(c.frame, frame);
  expect(c.effects, effects);
  expect(c.toy, same(toy));
}

_FakeContext _context({Offset position = const Offset(40, 260)}) =>
    _FakeContext(target: _target('target'), position: position);

PetActionPlan _plan(
  PetRuntimeAction action, {
  bool walk = false,
  Object? payload,
}) => PetActionPlan(
  runtimeAction: action,
  catalogAction: PetBehaviorAction.headTiltFocus,
  originTargetId: 'target',
  payload: payload,
  walkToward: walk,
);

PetMessageTarget _target(String id, {double left = 100, double top = 200}) =>
    PetMessageTarget(
      id: id,
      kind: WorldObjectKind.platform,
      contentKind: PetNormalizedContentKind.text,
      payload: id,
      messageText: id,
    )..markMeasuredBounds(Rect.fromLTWH(left, top, 100, 52));

class _FakeContext implements PetActionContext {
  _FakeContext({required this.target, required this.position});

  @override
  PetInteractable? target;
  @override
  Duration totalElapsed = Duration.zero;
  @override
  Duration phaseElapsed = Duration.zero;
  @override
  Duration previousTotalElapsed = Duration.zero;
  @override
  Duration previousPhaseElapsed = Duration.zero;
  @override
  Offset position;
  @override
  PetState state = PetState.idle;
  @override
  double direction = 1;
  int frame = -1;
  @override
  Size viewportSize = const Size(360, 800);
  @override
  PetBoundedInteractable? currentPlatform;
  @override
  double currentSurfaceY = 312;
  @override
  double heightAboveSurface = 0;
  @override
  BouncingEmojiToy? toy;
  @override
  double dustTimer = 1;
  final List<String> effects = [];
  final Map<String, double> deflections = {};
  int patrolResets = 0;
  PetActionEndReason? completed;

  void advance(int ms) {
    previousTotalElapsed = totalElapsed;
    previousPhaseElapsed = phaseElapsed;
    totalElapsed += Duration(milliseconds: ms);
    phaseElapsed += Duration(milliseconds: ms);
  }

  @override
  set frameIndex(int value) => frame = value;
  @override
  Offset messageSidePosition(
    PetInteractable target, {
    required bool useRightSide,
  }) => Offset(
    useRightSide ? target.bounds.right + 12 : target.bounds.left - 64,
    target.bounds.top - 12,
  );
  @override
  bool usesRightSideOf(Rect bounds) => position.dx >= bounds.center.dx;
  @override
  double bubbleDeflection(String id) => deflections[id] ?? 0;
  @override
  void bubbleImpulse(String id, double force) =>
      effects.add('impulse:$id:$force');
  @override
  void footsteps(Duration elapsed, {required bool isRunning}) =>
      effects.add('footsteps:${elapsed.inMilliseconds}:$isRunning');
  @override
  void spawnDust(Offset p) => effects.add('dust:${p.dx},${p.dy}');
  @override
  void spawnHeart(Offset p) => effects.add('heart:${p.dx},${p.dy}');
  @override
  void beginPhase() => phaseElapsed = Duration.zero;
  @override
  void resetPatrolClock() => patrolResets++;
  @override
  void complete([PetActionEndReason reason = PetActionEndReason.completed]) =>
      completed = reason;
}

class _StubHandler implements PetActionHandler {
  _StubHandler(this.action);
  @override
  final PetRuntimeAction action;
  @override
  void cancel(PetActionContext context, PetActionEndReason reason) {}
  @override
  void start(PetActionContext context, PetActionPlan plan) {}
  @override
  PetActionTickResult tick(PetActionContext context, Duration elapsed) =>
      PetActionTickResult.running;
}
