import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../chat/domain/chat_models.dart';
import '../../chat/domain/chat_message.dart' as domain;
import 'pet_action_plan.dart';
import 'pet_action_runner.dart';
import 'actions/pet_action_context.dart';
import 'pet_behavior_catalog.dart';
import 'pet_behavior_executor.dart';
import 'pet_behavior_normalizer.dart';
import 'pet_behavior_runtime.dart';
import 'pet_behavior_selector.dart';
import 'pet_message_target.dart';
import 'pet_message_target_factory.dart';
import 'pet_effects.dart';
import 'pet_world.dart';

enum PetActionType {
  none,
  jumpToPlatform,
  chaseEmoji,
  inspectGif,
  pawTest,
  dogProbe,
  parrotProbe,
  observeTarget,
}

class PetWorldController implements PetBehaviorRuntime {
  PetState state = PetState.idle;
  Offset position = const Offset(24, 24);
  List<PetMessageTarget> _objects = const [];
  List<PetMessageTarget> get objects => _objects;
  set objects(List<PetMessageTarget> targets) => setMessageTargets(targets);
  bool _hasMessageSnapshot = false;
  String? _messageSnapshotRoomId;
  final Set<({String roomId, String clientId})> _seenMessageSources = {};
  double _time = 0;
  double _walkDirection = 1;
  int _actionFrameIndex = 0;
  double? _actionSurfaceY;
  double _actionHeight = 0;
  Duration _lastActionTick = Duration.zero;
  Size _viewportSize = Size.zero;

  double get direction => _walkDirection;

  PetType _selectedPet = PetType.corgi;
  PetType get selectedPet => _selectedPet;
  set selectedPet(PetType newPet) => setPet(newPet);
  PetConfig get petConfig => PetConfig.of(selectedPet);

  void setPet(PetType newPet) {
    if (newPet != selectedPet) {
      _resetActiveAction(reason: PetActionEndReason.petChanged);
    }
    _selectedPet = newPet;
    pawPrints.clear();
    particles.clear();
    final center = Offset(position.dx + 32, position.dy + 16);
    if (newPet == PetType.parrot) {
      particles.add(
        PetParticle(
          position: center,
          kind: ParticleKind.note,
          velocity: const Offset(0, -40),
          maxLifetime: 1.2,
        ),
      );
    } else {
      particles.add(
        PetParticle(
          position: center,
          kind: ParticleKind.heart,
          velocity: const Offset(0, -40),
          maxLifetime: 1.2,
        ),
      );
    }
  }

  // Real-time interactive elements
  final List<PetParticle> particles = [];
  final List<PawPrint> pawPrints = [];
  BouncingEmojiToy? bouncingToy;
  PetActionType currentAction = PetActionType.none;
  PetBoundedInteractable? currentPlatform;
  double _pawStepTimer = 0.0;
  bool _isLeftPaw = false;

  /// Current surface Y level underneath the pet's horizontal center.
  /// During an airborne jump, this interpolates the projection surface plane.
  /// When on a message bubble platform, this incorporates real-time spring deflection.
  double get currentSurfaceY {
    if (_actionSurfaceY != null) return _actionSurfaceY!;
    if (currentPlatform != null) {
      return currentPlatform!.bounds.top +
          getBubbleDeflection(currentPlatform!.id);
    }
    return position.dy + 52.0;
  }

  /// Height of the pet's feet above the surface during an airborne arc.
  double get heightAboveSurface {
    return _actionHeight;
  }

  // Bubble spring physics
  final Map<String, BubbleSpring> _bubbleSprings = {};
  final ValueNotifier<int> springNotifier = ValueNotifier<int>(0);

  double getBubbleDeflection(String id) => _bubbleSprings[id]?.offset ?? 0.0;

  void triggerBubbleImpulse(String id, double force) {
    final spring = _bubbleSprings.putIfAbsent(id, () => BubbleSpring());
    spring.impulse(force);
    springNotifier.value++;
  }

  // Action target
  final PetActionRunner _actionRunner = PetActionRunner();
  double _dustTimer = 0.0;
  double _stepBounceTimer = 0.0;
  _PendingStimulus? _pendingStimulus;

  PetInteractable? get activeTarget => _actionRunner.target;
  Object? get activePayload => _actionRunner.payload;
  int get frameIndex {
    if (currentAction != PetActionType.none) return _actionFrameIndex;
    switch (state) {
      case PetState.idle:
        return (_time / 0.25).floor() % 4;
      case PetState.walk:
        return (_time / 0.15).floor() % 4;
      case PetState.run:
        return (_time / 0.12).floor() % 2;
      case PetState.jump:
      case PetState.pounce:
        return (_time / 0.2).floor().clamp(0, 1);
      case PetState.observe:
        return (_time / 0.35).floor() % 2;
      case PetState.catStalk:
        return (_time / 0.18).floor() % 4;
      case PetState.pawTest:
      case PetState.dogProbe:
      case PetState.parrotProbe:
        return _actionFrameIndex;
    }
  }

  void loadRoom(ChatRoom room) {
    _objects = const [];
    _hasMessageSnapshot = false;
    _messageSnapshotRoomId = room.id;
    _seenMessageSources.clear();
    _pendingStimulus = null;
    state = PetState.idle;
    position = const Offset(24, 24);
    _time = 0;
    _walkDirection = 1;
    currentAction = PetActionType.none;
    currentPlatform = null;
    _actionRunner.end(PetActionEndReason.worldReset);
    _actionSurfaceY = null;
    _actionHeight = 0.0;
    _dustTimer = 0.0;
    _stepBounceTimer = 0.0;
    _pawStepTimer = 0.0;
    _isLeftPaw = false;
    bouncingToy = null;
    particles.clear();
    pawPrints.clear();
    _bubbleSprings.clear();
    setMessageTargets(
      room.messages.map(PetMessageTargetFactory.fromLegacyMessage),
    );
    springNotifier.value++;
  }

  /// Installs a room snapshot without inferring whether an item is live.
  /// Live behavior dispatch is owned by [handleMessageAdded].
  List<PetBehaviorExecutionResult> setMessageBubbleTargets(
    Iterable<domain.ChatMessage> messages, {
    String? roomId,
  }) {
    final targets = messages
        .map(PetMessageTargetFactory.fromDomainMessage)
        .toList();
    final snapshotRoomId =
        roomId ??
        (targets.isEmpty ? null : targets.first.sourceIdentity?.roomId) ??
        _messageSnapshotRoomId;
    setMessageTargets(targets);
    if (!_hasMessageSnapshot || snapshotRoomId != _messageSnapshotRoomId) {
      _seenMessageSources
        ..clear()
        ..addAll(targets.map((target) => target.sourceIdentity).nonNulls);
    }
    _hasMessageSnapshot = true;
    _messageSnapshotRoomId = snapshotRoomId;
    return const [];
  }

  PetBehaviorExecutionResult? handleMessageAdded(
    domain.ChatMessage message, {
    required bool isLive,
  }) {
    final target = PetMessageTargetFactory.fromDomainMessage(message);
    final source = target.sourceIdentity;
    if (source == null || source.roomId != _messageSnapshotRoomId) return null;
    if (!_seenMessageSources.add(source) || !isLive) return null;

    final existingIndex = objects.indexWhere(
      (candidate) => candidate.sourceIdentity == source,
    );
    final nextTargets = objects.toList();
    if (existingIndex < 0) {
      nextTargets.add(target);
    } else {
      nextTargets[existingIndex] = target;
    }
    setMessageTargets(nextTargets);
    final runtimeTarget = objects.firstWhere(
      (candidate) => candidate.sourceIdentity == source,
    );
    return dispatch(
      PetBehaviorNormalizer.fromTarget(
        runtimeTarget,
        PetStimulusType.newMessageBubble,
        petType: selectedPet,
      ),
    );
  }

  /// Replaces message data while transferring runtime ownership by identity.
  void setMessageTargets(Iterable<PetMessageTarget> targets) {
    final nextTargets = List<PetMessageTarget>.unmodifiable(targets);
    final byId = {for (final target in objects) target.id: target};
    final bySource = {
      for (final target in objects)
        if (target.sourceIdentity != null) target.sourceIdentity!: target,
    };
    final replacements = <PetMessageTarget, PetMessageTarget>{};
    final nextSprings = <String, BubbleSpring>{};
    for (final next in nextTargets) {
      final previous = bySource[next.sourceIdentity] ?? byId[next.id];
      if (previous == null ||
          previous.sourceIdentity?.roomId != next.sourceIdentity?.roomId) {
        continue;
      }
      replacements[previous] = next;
      if (!next.hasMeasuredBounds && previous.hasMeasuredBounds) {
        next.markMeasuredBounds(previous.bounds);
      }
      final spring = _bubbleSprings[previous.id];
      if (spring != null) nextSprings[next.id] = spring;
    }

    final active = _actionRunner.target;
    final nextActive = replacements[active];
    final platform = currentPlatform;
    final nextPlatform = replacements[platform];
    final pending = _pendingStimulus;
    _objects = nextTargets;
    if ((active != null &&
            (nextActive == null || nextActive.kind != active.kind)) ||
        (platform != null && nextPlatform == null)) {
      _resetActiveAction(reason: PetActionEndReason.targetRemoved);
    } else {
      if (nextActive != null) _actionRunner.retarget(nextActive);
      currentPlatform = nextPlatform;
      if (pending != null) {
        final nextPending = replacements[pending.target];
        _pendingStimulus = nextPending != null && pending.matches(nextPending)
            ? _PendingStimulus(nextPending, pending.stimulus, pending.action)
            : null;
      }
    }
    final springsChanged = !mapEquals(_bubbleSprings, nextSprings);
    _bubbleSprings
      ..clear()
      ..addAll(nextSprings);
    _syncTargetGeometry();
    // Notify only after references, readiness and canonical spring keys agree.
    if (springsChanged) springNotifier.value++;
  }

  void _resetActiveAction({required PetActionEndReason reason}) {
    _actionRunner.end(reason);
    currentPlatform = null;
    currentAction = PetActionType.none;
    state = PetState.idle;
    bouncingToy = null;
    _pendingStimulus = null;
    _time = 0;
    _actionSurfaceY = null;
    _actionHeight = 0;
  }

  void updateObjectBounds(Map<String, Rect> boundsMap) {
    for (final obj in objects) {
      if (boundsMap.containsKey(obj.id)) {
        obj.markMeasuredBounds(boundsMap[obj.id]!);
      }
    }
    _syncTargetGeometry();
    _retryPendingStimulus();
  }

  void updateViewportSize(Size size) {
    _viewportSize = size;
  }

  void _syncTargetGeometry() {
    if (currentPlatform != null) {
      final bounds = currentPlatform!.bounds;
      final maxBoundX = math.max(bounds.left + 4, bounds.right - 56).toDouble();
      final springDeflection = getBubbleDeflection(currentPlatform!.id);
      position = Offset(
        position.dx.clamp(bounds.left + 4, maxBoundX),
        bounds.top - 52 + springDeflection,
      );
    }
  }

  void _retryPendingStimulus() {
    final pending = _pendingStimulus;
    if (pending == null) return;
    if (currentAction != PetActionType.none ||
        pending.stimulus.petType != selectedPet ||
        !objects.contains(pending.target) ||
        !pending.matches(pending.target)) {
      _pendingStimulus = null;
      return;
    }
    if (!pending.target.hasMeasuredBounds) return;
    final stimulus = PetBehaviorNormalizer.fromTarget(
      pending.target,
      pending.stimulus.stimulusType,
      petType: selectedPet,
    );
    _pendingStimulus = null;
    if (const PetBehaviorSelector().select(stimulus)?.action !=
        pending.action) {
      return;
    }
    dispatch(stimulus);
  }

  void tick(Duration elapsed) {
    final dt = elapsed.inMilliseconds / 1000;
    if (dt <= 0) return;

    _time += dt;
    _lastActionTick = Duration(milliseconds: elapsed.inMilliseconds);
    _actionRunner.advance(_lastActionTick);
    _dustTimer += dt;
    _stepBounceTimer += dt;

    // 1. Update bubble springs (Harmonic oscillator)
    var anySpringActive = false;
    for (final spring in _bubbleSprings.values) {
      if (spring.isActive) {
        spring.update(dt);
        anySpringActive = true;
      }
    }
    if (anySpringActive) {
      springNotifier.value++;
    }

    // 2. Update particles & paw prints
    for (final p in particles) {
      p.update(dt);
    }
    particles.removeWhere((p) => p.isDead);

    for (final paw in pawPrints) {
      paw.update(dt);
    }
    pawPrints.removeWhere((paw) => paw.isDead);

    // 3. Update bouncing toy
    if (bouncingToy != null) {
      bouncingToy!.update(dt);
      if (bouncingToy!.isFinished) {
        bouncingToy = null;
      }
    }

    // 4. Handle specific action sequence or default movement
    final hadAction = currentAction != PetActionType.none;
    if (hadAction) {
      _actionRunner.tick(_PetWorldActionContext(this), _lastActionTick);
    } else {
      _tickDefaultPatrol(dt);
    }
  }

  /// Compatibility entry point for existing tap callers.
  PetBehaviorExecutionResult interact(String objectId) {
    final target = _objectForId(objectId);
    if (target == null) {
      return PetBehaviorExecutionResult(
        status: PetBehaviorExecutionStatus.ignored,
        action: null,
        targetId: objectId,
        reason: 'no normalized target for user tap',
      );
    }
    return dispatch(
      PetBehaviorNormalizer.fromTarget(
        target,
        PetStimulusType.userTap,
        petType: selectedPet,
      ),
    );
  }

  /// Resolves a catalog behavior and delegates only approved runtime work.
  PetBehaviorExecutionResult dispatch(PetBehaviorStimulus stimulus) {
    final target = _objectForId(stimulus.targetId);
    if (target == null) {
      return PetBehaviorExecutionResult(
        status: PetBehaviorExecutionStatus.ignored,
        action: null,
        targetId: stimulus.targetId,
        reason: 'target is unavailable',
      );
    }
    if (stimulus.petType != selectedPet ||
        stimulus.sourceIdentity != target.sourceIdentity ||
        stimulus.targetKind != target.kind ||
        stimulus.contentKind != target.contentKind ||
        stimulus.payload != target.payload) {
      return PetBehaviorExecutionResult(
        status: PetBehaviorExecutionStatus.ignored,
        action: null,
        targetId: stimulus.targetId,
        reason: 'stimulus no longer matches selected pet or target',
      );
    }
    final selection = const PetBehaviorSelector().select(stimulus);
    if (selection == null) {
      return PetBehaviorExecutionResult(
        status: PetBehaviorExecutionStatus.ignored,
        action: null,
        targetId: stimulus.targetId,
        reason: 'no selection for stimulus',
      );
    }
    if (stimulus.stimulusType == PetStimulusType.newMessageBubble &&
        currentAction != PetActionType.none) {
      return PetBehaviorExecutionResult(
        status: PetBehaviorExecutionStatus.ignored,
        action: selection.action,
        targetId: stimulus.targetId,
        reason: 'active action is not interrupted by message arrival',
      );
    }
    final result = PetBehaviorExecutor(this).execute(selection, target);
    if (!target.hasMeasuredBounds && currentAction == PetActionType.none) {
      _pendingStimulus = _PendingStimulus(target, stimulus, selection.action);
    }
    return result;
  }

  PetMessageTarget? _objectForId(String objectId) => objects
      .cast<PetMessageTarget?>()
      .firstWhere((item) => item?.id == objectId, orElse: () => null);

  PetInteractable _beginRuntimeAction(
    PetActionPlan plan,
    PetInteractable target, {
    required double platformImpulse,
  }) {
    _cancelActiveRuntimeArtifacts(platformImpulse: platformImpulse);
    _pendingStimulus = null;
    final liveTarget = _objectForId(target.id) ?? target;
    currentAction = _actionTypeFor(plan.runtimeAction);
    _actionSurfaceY = null;
    _actionHeight = 0;
    _actionRunner.start(plan, liveTarget, _PetWorldActionContext(this));
    _time = 0.0;
    _dustTimer = 0.0;
    _stepBounceTimer = 0.0;
    return liveTarget;
  }

  @override
  void startAction(PetActionPlan plan, PetInteractable target) {
    _startPlannedAction(plan, target);
  }

  void _startPlannedAction(PetActionPlan plan, PetInteractable target) {
    _validateActionTarget(plan, target);
    final platformImpulse = plan.runtimeAction == PetRuntimeAction.chaseEmoji
        ? 70.0
        : 60.0;
    _beginRuntimeAction(plan, target, platformImpulse: platformImpulse);
  }

  PetActionType _actionTypeFor(PetRuntimeAction action) => switch (action) {
    PetRuntimeAction.jumpToPlatform => PetActionType.jumpToPlatform,
    PetRuntimeAction.chaseEmoji => PetActionType.chaseEmoji,
    PetRuntimeAction.inspectMedia => PetActionType.inspectGif,
    PetRuntimeAction.observeTarget => PetActionType.observeTarget,
    PetRuntimeAction.catPawTest => PetActionType.pawTest,
    PetRuntimeAction.dogProbe => PetActionType.dogProbe,
    PetRuntimeAction.parrotProbe => PetActionType.parrotProbe,
  };

  void _validateActionTarget(PetActionPlan plan, PetInteractable target) {
    if (plan.runtimeAction != PetRuntimeAction.jumpToPlatform) return;

    final liveTarget = _objectForId(target.id) ?? target;
    if (liveTarget is! PetBoundedInteractable) {
      throw ArgumentError.value(
        target,
        'target',
        'jumpToPlatform requires a bounded target',
      );
    }
  }

  void _cancelActiveRuntimeArtifacts({required double platformImpulse}) {
    if (currentPlatform != null) {
      triggerBubbleImpulse(currentPlatform!.id, platformImpulse);
      currentPlatform = null;
    }
    bouncingToy = null;
  }

  // --- Platform Jump (Standing/Walking on Bubble with Spring Landing) ---
  void startJumpToPlatform(PetBoundedInteractable target) {
    _startPlannedAction(
      PetActionPlan(
        runtimeAction: PetRuntimeAction.jumpToPlatform,
        catalogAction: PetBehaviorAction.nosePawBump,
        originTargetId: target.id,
      ),
      target,
    );
  }

  // --- Emoji Chase (Video 2: Emoji Bouncing & Corgi Chasing) ---
  void startChaseEmoji(PetInteractable target, {required Object? payload}) {
    _startPlannedAction(
      PetActionPlan(
        runtimeAction: PetRuntimeAction.chaseEmoji,
        catalogAction: PetBehaviorAction.runChase,
        originTargetId: target.id,
        payload: payload,
      ),
      target,
    );
  }

  // --- GIF Observe (Video 1: Look up -> Hearts -> Approach -> Paw on Bubble) ---
  void startInspectGif(PetInteractable target, {required Object? payload}) {
    _startPlannedAction(
      PetActionPlan(
        runtimeAction: PetRuntimeAction.inspectMedia,
        catalogAction: PetBehaviorAction.sniffBubble,
        originTargetId: target.id,
        payload: payload,
      ),
      target,
    );
  }

  void startPawTest(PetInteractable target) {
    _startPlannedAction(
      PetActionPlan(
        runtimeAction: PetRuntimeAction.catPawTest,
        catalogAction: PetBehaviorAction.pawTest,
        originTargetId: target.id,
      ),
      target,
    );
  }

  bool _usesRightSideOf(Rect bounds) {
    const petWidth = 64.0;
    const bubbleGap = 8.0;
    const requiredClearance = petWidth + bubbleGap;
    if (_viewportSize.width <= 0) return bounds.left < requiredClearance;

    final leftFits = bounds.left >= requiredClearance;
    final rightFits = bounds.right + requiredClearance <= _viewportSize.width;
    if (leftFits != rightFits) return rightFits;
    if (leftFits) return false;
    return _viewportSize.width - bounds.right > bounds.left;
  }

  Offset _messageSidePosition(
    PetInteractable target, {
    required bool useRightSide,
  }) {
    const petWidth = 64.0;
    const petHeight = 64.0;
    const feetOffset = 52.0;
    const bubbleGap = 8.0;
    final bounds = target.bounds;
    final x = useRightSide
        ? bounds.right + bubbleGap
        : bounds.left - petWidth - bubbleGap;
    final maxX = _viewportSize.width > 0
        ? math.max(0.0, _viewportSize.width - petWidth)
        : double.infinity;
    final y = bounds.bottom - feetOffset + getBubbleDeflection(target.id);
    final maxY = _viewportSize.height > 0
        ? math.max(0.0, _viewportSize.height - petHeight)
        : double.infinity;
    return Offset(x.clamp(0.0, maxX), y.clamp(0.0, maxY));
  }

  void startDogProbe(PetInteractable target) {
    _startPlannedAction(
      PetActionPlan(
        runtimeAction: PetRuntimeAction.dogProbe,
        catalogAction: PetBehaviorAction.novelObjectNoseProbe,
        originTargetId: target.id,
      ),
      target,
    );
  }

  void startParrotProbe(PetInteractable target) {
    _startPlannedAction(
      PetActionPlan(
        runtimeAction: PetRuntimeAction.parrotProbe,
        catalogAction: PetBehaviorAction.beakProbe,
        originTargetId: target.id,
      ),
      target,
    );
  }

  void startObserveTarget(PetInteractable target, {required bool walkToward}) {
    _startPlannedAction(
      PetActionPlan(
        runtimeAction: PetRuntimeAction.observeTarget,
        catalogAction: PetBehaviorAction.headTiltFocus,
        originTargetId: target.id,
        walkToward: walkToward,
      ),
      target,
    );
  }

  // --- Default Patrol (Walk / Idle on floor or bubble surface) ---
  void _tickDefaultPatrol(double dt) {
    if (currentPlatform != null) {
      // Patrol on the top surface of the current bubble platform
      final bounds = currentPlatform!.bounds;
      final minX = bounds.left + 4;
      final maxX = math.max(bounds.left + 4, bounds.right - 56).toDouble();
      final platformY = bounds.top - 52;
      final springDeflection = getBubbleDeflection(currentPlatform!.id);

      // Dog's position Y directly follows the spring deflection!
      position = Offset(position.dx, platformY + springDeflection);

      if (state == PetState.idle && _time > 1.5) {
        state = PetState.walk;
        _time = 0;
      } else if (state == PetState.walk) {
        final nextX = position.dx + dt * 36 * _walkDirection;
        if (nextX >= maxX) {
          _walkDirection = -1;
        } else if (nextX <= minX) {
          _walkDirection = 1;
        }

        // Micro-step impulse as corgi walks across the bubble
        if (_stepBounceTimer > 0.2) {
          _stepBounceTimer = 0.0;
          triggerBubbleImpulse(currentPlatform!.id, 14.0);
        }

        position = Offset(
          (position.dx + dt * 36 * _walkDirection).clamp(minX, maxX),
          platformY + springDeflection,
        );
        _handleFootsteps(dt, isRunning: false);

        if (_time > 2.0) {
          state = PetState.idle;
          _time = 0;
        }
      }
    } else {
      // Floor patrol (Original baseline logic)
      if (state == PetState.idle && _time > 1.5) {
        state = PetState.walk;
        _time = 0;
      } else if (state == PetState.walk) {
        final nextX = position.dx + dt * 48 * _walkDirection;
        if (nextX >= 280) {
          _walkDirection = -1;
        } else if (nextX <= 24) {
          _walkDirection = 1;
        }
        position = Offset(
          (position.dx + dt * 48 * _walkDirection).clamp(24, 280),
          position.dy,
        );
        _handleFootsteps(dt, isRunning: false);

        if (_time > 1.5) {
          state = PetState.idle;
          _time = 0;
        }
      }
    }
  }

  void _handleFootsteps(double dt, {required bool isRunning}) {
    if (heightAboveSurface > 1.0) return;

    _pawStepTimer += dt;
    final interval = isRunning ? 0.14 : 0.24;
    while (_pawStepTimer >= interval) {
      _pawStepTimer -= interval;
      _spawnPawPrint();
    }
  }

  void _spawnPawPrint() {
    _isLeftPaw = !_isLeftPaw;
    final pawX = position.dx + (_walkDirection > 0 ? 18.0 : 44.0);
    final pawY = currentSurfaceY - 4.0 + (_isLeftPaw ? -2.5 : 2.5);

    pawPrints.add(
      PawPrint(
        position: Offset(pawX, pawY),
        isLeftPaw: _isLeftPaw,
        direction: _walkDirection,
      ),
    );

    if (pawPrints.length > 20) {
      pawPrints.removeAt(0);
    }
  }

  void _spawnDust(Offset pos) {
    particles.add(
      PetParticle(
        position: pos,
        kind: ParticleKind.dust,
        velocity: Offset(-_walkDirection * 15, -10),
        maxLifetime: 0.45,
        initialSize: 6.0,
      ),
    );
  }

  void _spawnHeart(Offset pos) {
    final kind = (selectedPet == PetType.parrot)
        ? (math.Random().nextBool() ? ParticleKind.note : ParticleKind.feather)
        : ParticleKind.heart;
    particles.add(
      PetParticle(
        position: pos,
        kind: kind,
        velocity: Offset((math.Random().nextDouble() - 0.5) * 30, -50),
        maxLifetime: 1.0,
        initialSize: 14.0,
      ),
    );
  }
}

final class _PetWorldActionContext implements PetActionContext {
  _PetWorldActionContext(this.world);
  final PetWorldController world;
  @override
  PetInteractable? get target => world._actionRunner.target;
  @override
  Duration get totalElapsed => world._actionRunner.totalElapsed;
  @override
  Duration get phaseElapsed => world._actionRunner.phaseElapsed;
  @override
  Duration get previousTotalElapsed => world._actionRunner.previousTotalElapsed;
  @override
  Duration get previousPhaseElapsed => world._actionRunner.previousPhaseElapsed;
  @override
  Offset get position => world.position;
  @override
  set position(Offset value) => world.position = value;
  @override
  PetState get state => world.state;
  @override
  set state(PetState value) => world.state = value;
  @override
  double get direction => world._walkDirection;
  @override
  set direction(double value) => world._walkDirection = value;
  @override
  set frameIndex(int value) => world._actionFrameIndex = value;
  @override
  Size get viewportSize => world._viewportSize;
  @override
  PetBoundedInteractable? get currentPlatform => world.currentPlatform;
  @override
  set currentPlatform(PetBoundedInteractable? value) =>
      world.currentPlatform = value;
  @override
  double get currentSurfaceY => world.currentSurfaceY;
  @override
  set currentSurfaceY(double value) => world._actionSurfaceY = value;
  @override
  double get heightAboveSurface => world.heightAboveSurface;
  @override
  set heightAboveSurface(double value) => world._actionHeight = value;
  @override
  BouncingEmojiToy? get toy => world.bouncingToy;
  @override
  set toy(BouncingEmojiToy? value) => world.bouncingToy = value;
  @override
  double get dustTimer => world._dustTimer;
  @override
  set dustTimer(double value) => world._dustTimer = value;
  @override
  Offset messageSidePosition(
    PetInteractable target, {
    required bool useRightSide,
  }) => world._messageSidePosition(target, useRightSide: useRightSide);
  @override
  bool usesRightSideOf(Rect bounds) => world._usesRightSideOf(bounds);
  @override
  double bubbleDeflection(String id) => world.getBubbleDeflection(id);
  @override
  void bubbleImpulse(String id, double force) =>
      world.triggerBubbleImpulse(id, force);
  @override
  void footsteps(Duration elapsed, {required bool isRunning}) => world
      ._handleFootsteps(elapsed.inMilliseconds / 1000, isRunning: isRunning);
  @override
  void spawnDust(Offset position) => world._spawnDust(position);
  @override
  void spawnHeart(Offset position) => world._spawnHeart(position);
  @override
  void beginPhase() => world._actionRunner.beginPhase();
  @override
  void resetPatrolClock() => world._time = 0;
  @override
  void complete([PetActionEndReason reason = PetActionEndReason.completed]) {
    world.currentAction = PetActionType.none;
    world._actionSurfaceY = null;
    world._actionHeight = 0;
    world._actionRunner.end(reason);
  }
}

class _PendingStimulus {
  const _PendingStimulus(this.target, this.stimulus, this.action);

  final PetMessageTarget target;
  final PetBehaviorStimulus stimulus;
  final PetBehaviorAction action;

  bool matches(PetMessageTarget candidate) =>
      candidate.sourceIdentity == stimulus.sourceIdentity &&
      candidate.kind == stimulus.targetKind &&
      candidate.contentKind == stimulus.contentKind &&
      candidate.payload == stimulus.payload;
}
