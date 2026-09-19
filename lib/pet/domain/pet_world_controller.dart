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
  Size _viewportSize = Size.zero;

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
  Offset _pawTestStart = Offset.zero;
  Offset _pawTestTarget = Offset.zero;
  bool _pawTestUsesRightSide = false;
  bool _pawTestFirstImpact = false;
  bool _pawTestSecondImpact = false;
  Offset _probeStart = Offset.zero;
  bool _probeUsesRightSide = false;
  bool _probeFirstImpact = false;
  bool _probeSecondImpact = false;
  bool _inspectUsesRightSide = false;
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
      case PetState.catStalk:
        return (_time / 0.18).floor() % 4;
      case PetState.pawTest:
        return _pawTestFrameIndex;
      case PetState.dogProbe:
        return _dogProbeFrameIndex;
      case PetState.parrotProbe:
        return _parrotProbeFrameIndex;
    }
  }

  int get _pawTestFrameIndex {
    final elapsedMs = (_actionElapsed * 1000).round();
    if (elapsedMs < 1850) return 0;
    if (elapsedMs < 2000) return 1;
    if (elapsedMs < 2150) return 2;
    if (elapsedMs < 2300) return 3;
    if (elapsedMs < 2450) return 4;
    return 5;
  }

  int get _dogProbeFrameIndex {
    if (_actionElapsed < 0.2) return 0;
    if (_actionElapsed < 0.65) return 1;
    if (_actionElapsed < 1.0) return 2;
    if (_actionElapsed < 1.7) return 3;
    if (_actionElapsed < 2.3) return 4;
    return 5;
  }

  int get _parrotProbeFrameIndex {
    if (_actionElapsed < 0.2) return 0;
    if (_actionElapsed < 0.45) return 1;
    if (_actionElapsed < 0.7) return 2;
    if (_actionElapsed < 1.7) return 3;
    if (_actionElapsed < 2.3) return 4;
    return 5;
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

  void updateViewportSize(Size size) {
    _viewportSize = size;
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
      case PetActionType.pawTest:
        _tickPawTest(dt);
        break;
      case PetActionType.dogProbe:
        _tickDogProbe(dt);
        break;
      case PetActionType.parrotProbe:
        _tickParrotProbe(dt);
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
    _inspectUsesRightSide = _usesRightSideOf(target.bounds);
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

    final targetPosition = _messageSidePosition(
      target,
      useRightSide: _inspectUsesRightSide,
    );

    if (_actionElapsed < 0.6) {
      // Phase 1: Alert & watch with ears perked
      state = PetState.observe;
      _walkDirection = targetPosition.dx >= position.dx ? 1.0 : -1.0;
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
      final dx = targetPosition.dx - position.dx;
      final dy = targetPosition.dy - position.dy;
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
      position = targetPosition;
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
  void startPawTest(PetInteractable target) {
    final liveTarget = _beginRuntimeAction(target, null, platformImpulse: 60.0);
    _pawTestStart = position;
    _pawTestUsesRightSide = _usesRightSideOf(liveTarget.bounds);
    _pawTestTarget = _messageSidePosition(
      liveTarget,
      useRightSide: _pawTestUsesRightSide,
    );
    _walkDirection = _pawTestTarget.dx >= position.dx ? 1.0 : -1.0;
    _pawTestFirstImpact = false;
    _pawTestSecondImpact = false;
    currentAction = PetActionType.pawTest;
    state = PetState.catStalk;
  }

  void _tickPawTest(double dt) {
    final target = _activeTarget;
    if (target == null) {
      currentAction = PetActionType.none;
      state = PetState.idle;
      return;
    }

    _pawTestTarget = _messageSidePosition(
      target,
      useRightSide: _pawTestUsesRightSide,
    );
    final elapsedMs = (_actionElapsed * 1000).round();
    final previousElapsedMs = ((_actionElapsed - dt) * 1000).round();
    if (!_pawTestFirstImpact && previousElapsedMs < 2000 && elapsedMs >= 2000) {
      _pawTestFirstImpact = true;
      triggerBubbleImpulse(target.id, 45.0);
    }
    if (!_pawTestSecondImpact &&
        previousElapsedMs < 2450 &&
        elapsedMs >= 2450) {
      _pawTestSecondImpact = true;
      triggerBubbleImpulse(target.id, 32.0);
    }
    final firstStop = Offset.lerp(_pawTestStart, _pawTestTarget, 0.35)!;
    if (_actionElapsed < 0.55) {
      position = _pawTestStart;
      state = PetState.catStalk;
      return;
    }
    if (_actionElapsed < 1.0) {
      final progress = _easeInOut((_actionElapsed - 0.55) / 0.45);
      final movementDx = _pawTestTarget.dx - position.dx;
      if (movementDx.abs() > 0.001) {
        _walkDirection = movementDx.isNegative ? -1.0 : 1.0;
      }
      position = Offset.lerp(_pawTestStart, firstStop, progress)!;
      state = PetState.catStalk;
      _handleFootsteps(dt, isRunning: false);
      return;
    }
    if (_actionElapsed < 1.3) {
      position = firstStop;
      state = PetState.catStalk;
      return;
    }
    if (_actionElapsed < 1.7) {
      final progress = _easeInOut((_actionElapsed - 1.3) / 0.4);
      position = Offset.lerp(firstStop, _pawTestTarget, progress)!;
      state = PetState.catStalk;
      _handleFootsteps(dt, isRunning: false);
      return;
    }

    position = _pawTestTarget;
    _walkDirection = _pawTestUsesRightSide ? -1.0 : 1.0;
    if (_actionElapsed < 3.0) {
      state = PetState.pawTest;
      return;
    }

    currentAction = PetActionType.none;
    state = PetState.idle;
    _time = 0.0;
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

  @override
  void startDogProbe(PetInteractable target) {
    final liveTarget = _beginRuntimeAction(target, null, platformImpulse: 60.0);
    _startSpeciesProbe(liveTarget);
    currentAction = PetActionType.dogProbe;
    state = PetState.dogProbe;
  }

  void _tickDogProbe(double dt) {
    final target = _activeTarget;
    if (target == null) {
      currentAction = PetActionType.none;
      state = PetState.idle;
      return;
    }
    final targetPosition = _messageSidePosition(
      target,
      useRightSide: _probeUsesRightSide,
    );
    final elapsedMs = (_actionElapsed * 1000).round();
    final previousElapsedMs = ((_actionElapsed - dt) * 1000).round();
    if (!_probeFirstImpact && previousElapsedMs < 1700 && elapsedMs >= 1700) {
      _probeFirstImpact = true;
      triggerBubbleImpulse(target.id, 24.0);
    }
    if (!_probeSecondImpact && previousElapsedMs < 2300 && elapsedMs >= 2300) {
      _probeSecondImpact = true;
      triggerBubbleImpulse(target.id, 18.0);
    }
    if (_actionElapsed < 0.2) {
      position = _probeStart;
    } else if (_actionElapsed < 1.0) {
      final progress = _easeInOut((_actionElapsed - 0.2) / 0.8);
      final base = Offset.lerp(_probeStart, targetPosition, progress)!;
      position = base.translate(0, -math.sin(math.pi * progress) * 18);
      _walkDirection = targetPosition.dx >= _probeStart.dx ? 1.0 : -1.0;
    } else {
      position = targetPosition;
      _walkDirection = _probeUsesRightSide ? -1.0 : 1.0;
    }
    state = PetState.dogProbe;
    if (_actionElapsed >= 2.8) {
      currentAction = PetActionType.none;
      state = PetState.idle;
    }
  }

  @override
  void startParrotProbe(PetInteractable target) {
    final liveTarget = _beginRuntimeAction(target, null, platformImpulse: 60.0);
    _startSpeciesProbe(liveTarget);
    currentAction = PetActionType.parrotProbe;
    state = PetState.parrotProbe;
  }

  void _tickParrotProbe(double dt) {
    final target = _activeTarget;
    if (target == null) {
      currentAction = PetActionType.none;
      state = PetState.idle;
      return;
    }
    final targetPosition = _messageSidePosition(
      target,
      useRightSide: _probeUsesRightSide,
    );
    final elapsedMs = (_actionElapsed * 1000).round();
    final previousElapsedMs = ((_actionElapsed - dt) * 1000).round();
    if (!_probeFirstImpact && previousElapsedMs < 1700 && elapsedMs >= 1700) {
      _probeFirstImpact = true;
      triggerBubbleImpulse(target.id, 20.0);
    }
    if (!_probeSecondImpact && previousElapsedMs < 2300 && elapsedMs >= 2300) {
      _probeSecondImpact = true;
      triggerBubbleImpulse(target.id, 14.0);
    }
    if (_actionElapsed < 0.2) {
      position = _probeStart;
    } else if (_actionElapsed < 0.7) {
      final progress = _easeInOut((_actionElapsed - 0.2) / 0.5);
      position = Offset.lerp(_probeStart, targetPosition, progress)!;
      _walkDirection = targetPosition.dx >= _probeStart.dx ? 1.0 : -1.0;
    } else {
      position = targetPosition;
      _walkDirection = _probeUsesRightSide ? -1.0 : 1.0;
    }
    state = PetState.parrotProbe;
    if (_actionElapsed >= 2.7) {
      currentAction = PetActionType.none;
      state = PetState.idle;
    }
  }

  void _startSpeciesProbe(PetInteractable target) {
    _probeStart = position;
    _probeUsesRightSide = _usesRightSideOf(target.bounds);
    _probeFirstImpact = false;
    _probeSecondImpact = false;
    final targetPosition = _messageSidePosition(
      target,
      useRightSide: _probeUsesRightSide,
    );
    _walkDirection = targetPosition.dx >= position.dx ? 1.0 : -1.0;
  }

  double _easeInOut(double value) {
    final t = value.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
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
      if (_actionElapsed >= 0.9) {
        currentAction = PetActionType.none;
        state = PetState.idle;
        _activeTarget = null;
      }
      return;
    }

    final targetPosition = _messageSidePosition(
      target,
      useRightSide: _usesRightSideOf(target.bounds),
    );
    final dx = targetPosition.dx - position.dx;
    final dy = targetPosition.dy - position.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance <= 12) {
      _walkTowardObservationTarget = false;
      state = PetState.observe;
      _actionElapsed = 0;
      return;
    }

    state = PetState.walk;
    _walkDirection = dx >= 0 ? 1.0 : -1.0;
    const speed = 90.0;
    final step = speed * dt;
    if (step >= distance) {
      position = targetPosition;
      _walkTowardObservationTarget = false;
      state = PetState.observe;
      _actionElapsed = 0;
      return;
    }
    position = Offset(
      position.dx + (dx / distance) * step,
      position.dy + (dy / distance) * step,
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
