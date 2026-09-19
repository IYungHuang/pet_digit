import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../chat/domain/chat_models.dart';
import '../../chat/domain/chat_message.dart' as domain;
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
  double _time = 0;
  double _walkDirection = 1;

  double get direction => _walkDirection;

  PetType _selectedPet = PetType.corgi;
  PetType get selectedPet => _selectedPet;
  set selectedPet(PetType newPet) => setPet(newPet);
  PetConfig get petConfig => PetConfig.of(selectedPet);

  void setPet(PetType newPet) {
    if (newPet != selectedPet) _resetActiveAction();
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
    if (currentAction == PetActionType.jumpToPlatform) {
      final progress = (_jumpTime / _jumpDuration).clamp(0.0, 1.0);
      final startSurface = _jumpStart.dy + 52.0;
      final targetSurface = _jumpTarget.dy + 52.0;
      return startSurface + (targetSurface - startSurface) * progress;
    }
    if (currentPlatform != null) {
      return currentPlatform!.bounds.top +
          getBubbleDeflection(currentPlatform!.id);
    }
    return position.dy + 52.0;
  }

  /// Height of the pet's feet above the surface during an airborne arc.
  double get heightAboveSurface {
    if (currentAction == PetActionType.jumpToPlatform) {
      final progress = (_jumpTime / _jumpDuration).clamp(0.0, 1.0);
      return 4 * _jumpArcHeight * progress * (1.0 - progress);
    }
    return 0.0;
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

  // Jump interpolation
  Offset _jumpStart = Offset.zero;
  Offset _jumpTarget = Offset.zero;
  double _jumpDuration = 0.55;
  double _jumpTime = 0.0;
  double _jumpArcHeight = 45.0;

  // Action target
  PetInteractable? _activeTarget;
  Object? _activePayload;
  bool _walkTowardObservationTarget = false;
  double _actionElapsed = 0.0;
  double _dustTimer = 0.0;
  double _stepBounceTimer = 0.0;
  _PendingStimulus? _pendingStimulus;

  PetInteractable? get activeTarget => _activeTarget;
  Object? get activePayload => _activePayload;

  int get frameIndex {
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
    }
  }

  void loadRoom(ChatRoom room) {
    _objects = const [];
    _hasMessageSnapshot = false;
    _messageSnapshotRoomId = room.id;
    _pendingStimulus = null;
    state = PetState.idle;
    position = const Offset(24, 24);
    _time = 0;
    _walkDirection = 1;
    currentAction = PetActionType.none;
    currentPlatform = null;
    _activeTarget = null;
    _activePayload = null;
    _walkTowardObservationTarget = false;
    _actionElapsed = 0.0;
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

  /// Installs a room snapshot, then emits arrivals only for added identities.
  /// The first snapshot after room entry is history, including an empty one.
  /// Without event provenance, later history additions are indistinguishable
  /// from live arrivals. Call [setMessageTargets] for explicit history installs.
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
    final isBaseline =
        !_hasMessageSnapshot ||
        (_messageSnapshotRoomId != null &&
            snapshotRoomId != _messageSnapshotRoomId);
    final previousSources = {
      for (final target in objects)
        if (target.sourceIdentity != null) target.sourceIdentity!,
    };
    final previousIds = {
      for (final target in objects)
        (roomId: target.sourceIdentity?.roomId, id: target.id),
    };
    final additions = isBaseline
        ? const <PetMessageTarget>[]
        : targets
              .where(
                (target) =>
                    !previousSources.contains(target.sourceIdentity) &&
                    !previousIds.contains((
                      roomId: target.sourceIdentity?.roomId,
                      id: target.id,
                    )),
              )
              .toList();

    setMessageTargets(targets);
    _hasMessageSnapshot = true;
    _messageSnapshotRoomId = snapshotRoomId;
    // Installation and reconciliation must finish before any event dispatch.
    return [
      for (final target in additions)
        dispatch(
          PetBehaviorNormalizer.fromTarget(
            target,
            PetStimulusType.newMessageBubble,
            petType: selectedPet,
          ),
        ),
    ];
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

    final active = _activeTarget;
    final nextActive = replacements[active];
    final platform = currentPlatform;
    final nextPlatform = replacements[platform];
    final pending = _pendingStimulus;
    _objects = nextTargets;
    if ((active != null &&
            (nextActive == null || nextActive.kind != active.kind)) ||
        (platform != null && nextPlatform == null)) {
      _resetActiveAction();
    } else {
      _activeTarget = nextActive;
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

  void _resetActiveAction() {
    _activeTarget = null;
    _activePayload = null;
    currentPlatform = null;
    currentAction = PetActionType.none;
    state = PetState.idle;
    bouncingToy = null;
    _walkTowardObservationTarget = false;
    _pendingStimulus = null;
    _actionElapsed = 0;
    _time = 0;
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

  void _syncTargetGeometry() {
    if (currentAction == PetActionType.jumpToPlatform &&
        _activeTarget != null) {
      _jumpTarget = _platformLandingPosition(_activeTarget!.bounds);
    }
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
    _actionElapsed += dt;
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
    switch (currentAction) {
      case PetActionType.jumpToPlatform:
        _tickJumpToPlatform(dt);
        break;
      case PetActionType.chaseEmoji:
        _tickChaseEmoji(dt);
        break;
      case PetActionType.inspectGif:
        _tickInspectGif(dt);
        break;
      case PetActionType.observeTarget:
        _tickObserveTarget(dt);
        break;
      case PetActionType.none:
        _tickDefaultPatrol(dt);
        break;
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
    PetInteractable target,
    Object? payload, {
    required double platformImpulse,
  }) {
    _cancelActiveRuntimeArtifacts(platformImpulse: platformImpulse);
    _pendingStimulus = null;
    final liveTarget = _objectForId(target.id) ?? target;
    _activeTarget = liveTarget;
    _activePayload = payload;
    _actionElapsed = 0.0;
    _time = 0.0;
    _dustTimer = 0.0;
    _stepBounceTimer = 0.0;
    return liveTarget;
  }

  void _cancelActiveRuntimeArtifacts({required double platformImpulse}) {
    if (currentPlatform != null) {
      triggerBubbleImpulse(currentPlatform!.id, platformImpulse);
      currentPlatform = null;
    }
    bouncingToy = null;
    _walkTowardObservationTarget = false;
  }

  // --- Platform Jump (Standing/Walking on Bubble with Spring Landing) ---
  @override
  void startJumpToPlatform(PetBoundedInteractable target) {
    final liveTarget = _beginRuntimeAction(target, null, platformImpulse: 60.0);
    _startJumpToPlatform(
      liveTarget is PetBoundedInteractable ? liveTarget : target,
    );
  }

  void _startJumpToPlatform(PetBoundedInteractable target) {
    currentAction = PetActionType.jumpToPlatform;
    _jumpTarget = _platformLandingPosition(target.bounds);
    _walkDirection = _jumpTarget.dx >= position.dx ? 1.0 : -1.0;
    _jumpStart = position;
    _jumpDuration = 0.55;
    _jumpTime = 0.0;
    _jumpArcHeight = math.max(
      35.0,
      (_jumpStart.dy - _jumpTarget.dy).abs() * 0.4 + 25.0,
    );
    state = PetState.jump;
  }

  Offset _platformLandingPosition(Rect bounds) {
    final maxX = math.max(bounds.left + 4, bounds.right - 56).toDouble();
    return Offset(
      (bounds.center.dx - 32).clamp(bounds.left + 4, maxX),
      bounds.top - 52,
    );
  }

  void _tickJumpToPlatform(double dt) {
    _jumpTime += dt;
    final progress = (_jumpTime / _jumpDuration).clamp(0.0, 1.0);

    // Parabolic trajectory
    final linearX = _jumpStart.dx + (_jumpTarget.dx - _jumpStart.dx) * progress;
    final linearY = _jumpStart.dy + (_jumpTarget.dy - _jumpStart.dy) * progress;
    final arc = 4 * _jumpArcHeight * progress * (1.0 - progress);

    position = Offset(linearX, linearY - arc);

    if (progress >= 1.0) {
      currentAction = PetActionType.none;
      currentPlatform = _activeTarget as PetBoundedInteractable?;
      state = PetState.idle;
      _time = 0.0;

      // IMPACT! Trigger downward spring oscillation on the message bubble
      if (currentPlatform != null) {
        triggerBubbleImpulse(currentPlatform!.id, 160.0);
      }

      position = Offset(
        _jumpTarget.dx,
        _jumpTarget.dy +
            (currentPlatform != null
                ? getBubbleDeflection(currentPlatform!.id)
                : 0),
      );

      // Spawn landing dust puffs
      _spawnDust(position.translate(16, 52));
      _spawnDust(position.translate(40, 52));
    }
  }

  // --- Emoji Chase (Video 2: Emoji Bouncing & Corgi Chasing) ---
  @override
  void startChaseEmoji(PetInteractable target, {required Object? payload}) {
    final liveTarget = _beginRuntimeAction(
      target,
      payload,
      platformImpulse: 70.0,
    );
    _startChaseEmoji(liveTarget, payload: payload);
  }

  void _startChaseEmoji(PetInteractable target, {required Object? payload}) {
    currentAction = PetActionType.chaseEmoji;
    state = PetState.pounce;

    final bubbleCenter = target.bounds.center;
    // Launch emoji away from current corgi side
    final launchDirection = bubbleCenter.dx >= position.dx ? 1.0 : -1.0;
    final groundY = math.max(position.dy + 70, target.bounds.bottom + 40);

    bouncingToy = BouncingEmojiToy(
      emoji: payload is String && payload.isNotEmpty ? payload : '👋',
      start: bubbleCenter,
      groundY: groundY,
      direction: launchDirection,
    );
  }

  void _tickChaseEmoji(double dt) {
    if (bouncingToy == null || bouncingToy!.isFinished) {
      currentAction = PetActionType.none;
      state = PetState.idle;
      _time = 0.0;
      return;
    }

    final toy = bouncingToy!;
    final targetX = (toy.position.dx - 32 * toy.direction).clamp(16.0, 310.0);
    final targetY = toy.position.dy - 44;

    final dx = targetX - position.dx;
    final dy = targetY - position.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    if (dist > 15 && !toy.isCaught) {
      // Running after emoji
      state = PetState.run;
      _walkDirection = dx >= 0 ? 1.0 : -1.0;
      const speed = 190.0;
      final moveX = (dx / dist) * speed * dt;
      final moveY = (dy / dist) * speed * dt;

      position = Offset(
        (position.dx + moveX).clamp(16.0, 310.0),
        (position.dy + moveY).clamp(16.0, 800.0),
      );

      // Dust puff trail while running (Video 2)
      if (_dustTimer > 0.08) {
        _dustTimer = 0.0;
        _spawnDust(position.translate(direction > 0 ? 12 : 44, 52));
      }
      _handleFootsteps(dt, isRunning: true);
    } else {
      // Caught the emoji! Pounce & celebrate
      toy.isCaught = true;
      state = PetState.pounce;
      if (_actionElapsed > 1.2) {
        currentAction = PetActionType.none;
        state = PetState.idle;
        _time = 0.0;
        bouncingToy = null;
      }
    }
  }

  // --- GIF Observe (Video 1: Look up -> Hearts -> Approach -> Paw on Bubble) ---
  @override
  void startInspectGif(PetInteractable target, {required Object? payload}) {
    final liveTarget = _beginRuntimeAction(
      target,
      payload,
      platformImpulse: 60.0,
    );
    _startInspectGif(liveTarget);
  }

  void _startInspectGif(PetInteractable target) {
    currentAction = PetActionType.inspectGif;
    state = PetState.observe;
  }

  void _tickInspectGif(double dt) {
    final target = _activeTarget;
    if (target == null) {
      currentAction = PetActionType.none;
      state = PetState.idle;
      return;
    }

    final bounds = target.bounds;
    final watchX = (bounds.left + 16).clamp(16.0, 280.0);
    final targetUnder = Offset(watchX, bounds.bottom - 12);

    if (_actionElapsed < 0.6) {
      // Phase 1: Alert & watch with ears perked
      state = PetState.observe;
      _walkDirection = watchX >= position.dx ? 1.0 : -1.0;
    } else if (_actionElapsed < 1.2) {
      // Phase 2: Excited tail wagging & floating hearts (Video 1)
      state = PetState.observe;
      if (_dustTimer > 0.25) {
        _dustTimer = 0.0;
        _spawnHeart(position.translate(32, 8));
      }
    } else if (_actionElapsed < 1.9) {
      // Phase 3: Approach towards bottom of GIF bubble
      state = PetState.run;
      final dx = targetUnder.dx - position.dx;
      final dy = targetUnder.dy - position.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist > 6) {
        _walkDirection = dx >= 0 ? 1.0 : -1.0;
        const speed = 140.0;
        position = Offset(
          position.dx + (dx / dist) * speed * dt,
          position.dy + (dy / dist) * speed * dt,
        );
        _handleFootsteps(dt, isRunning: true);
      }
    } else if (_actionElapsed < 2.8) {
      // Phase 4: Leap up with front paws resting on the bottom border of the GIF (Video 1 00:09)
      state = PetState.pounce;
      position = targetUnder;
      if (_dustTimer > 0.2) {
        _dustTimer = 0.0;
        _spawnHeart(position.translate(20, -10));
      }
    } else {
      // Phase 5: Complete sequence
      currentAction = PetActionType.none;
      state = PetState.idle;
      _time = 0.0;
    }
  }

  @override
  void startObserveTarget(PetInteractable target, {required bool walkToward}) {
    _beginRuntimeAction(target, null, platformImpulse: 60.0);
    currentAction = PetActionType.observeTarget;
    _walkTowardObservationTarget = walkToward;
    state = walkToward ? PetState.walk : PetState.observe;
  }

  void _tickObserveTarget(double dt) {
    final target = _activeTarget;
    if (target == null) {
      currentAction = PetActionType.none;
      state = PetState.idle;
      return;
    }
    if (!_walkTowardObservationTarget) {
      state = PetState.observe;
      return;
    }

    final targetPosition = Offset(
      target.bounds.center.dx - 32,
      target.bounds.bottom - 52,
    );
    final dx = targetPosition.dx - position.dx;
    final dy = targetPosition.dy - position.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance <= 12) {
      _walkTowardObservationTarget = false;
      state = PetState.observe;
      return;
    }

    state = PetState.walk;
    _walkDirection = dx >= 0 ? 1.0 : -1.0;
    const speed = 90.0;
    position = Offset(
      position.dx + (dx / distance) * speed * dt,
      position.dy + (dy / distance) * speed * dt,
    );
    _handleFootsteps(dt, isRunning: false);
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
