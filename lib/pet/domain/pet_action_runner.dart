import 'pet_action_plan.dart';
import 'pet_world.dart';
import 'actions/pet_action_context.dart';
import 'actions/pet_action_handler.dart';
import 'actions/cat_paw_test_action.dart';
import 'actions/chase_emoji_action.dart';
import 'actions/dog_probe_action.dart';
import 'actions/inspect_media_action.dart';
import 'actions/jump_to_platform_action.dart';
import 'actions/observe_target_action.dart';
import 'actions/parrot_probe_action.dart';

export 'actions/pet_action_handler.dart'
    show PetActionEndReason, PetActionTickResult;

/// Owns action identity, live compatibility bindings, and action clocks.
///
/// Timeline behavior remains in [PetWorldController] until handler extraction.
class PetActionRunner {
  PetActionRunner({
    Iterable<MapEntry<PetRuntimeAction, PetActionHandler Function()>>?
    handlerFactories,
  }) : _handlerFactories = _validateFactories(
         handlerFactories ?? _defaultHandlerFactories,
       );

  final Map<PetRuntimeAction, PetActionHandler Function()> _handlerFactories;
  PetActionHandler? _handler;
  PetActionContext? _context;
  PetActionPlan? _activePlan;
  PetInteractable? _target;
  Object? _payload;
  Duration _totalElapsed = Duration.zero;
  Duration _phaseElapsed = Duration.zero;
  PetActionEndReason? _lastEndReason;

  PetActionPlan? get activePlan => _activePlan;
  PetInteractable? get target => _target;
  Object? get payload => _payload;
  Duration get totalElapsed => _totalElapsed;
  Duration get phaseElapsed => _phaseElapsed;
  PetActionEndReason? get lastEndReason => _lastEndReason;
  PetActionHandler? get activeHandler => _handler;

  PetActionHandler createHandler(PetRuntimeAction action) =>
      _handlerFactories[action]!();

  void start(
    PetActionPlan plan,
    PetInteractable target, [
    PetActionContext? context,
  ]) {
    if (_activePlan != null || _target != null || _payload != null) {
      end(PetActionEndReason.replaced);
    } else {
      _lastEndReason = null;
    }
    _activePlan = plan;
    _target = target;
    _payload = plan.payload;
    _totalElapsed = Duration.zero;
    _phaseElapsed = Duration.zero;
    if (context != null) {
      _context = context;
      _handler = createHandler(plan.runtimeAction);
      _handler!.start(context, plan);
    }
  }

  void advance(Duration elapsed) {
    if (_activePlan == null || elapsed <= Duration.zero) return;
    _totalElapsed += elapsed;
    _phaseElapsed += elapsed;
  }

  void beginPhase() {
    if (_activePlan == null) return;
    _phaseElapsed = Duration.zero;
  }

  void retarget(PetInteractable replacement) {
    if (_target == null) return;
    _target = replacement;
  }

  void end(PetActionEndReason reason) {
    final handler = _handler;
    final context = _context;
    if (handler != null && context != null) {
      handler.cancel(context, reason);
    }
    final action = _activePlan?.runtimeAction;
    final retention = reason == PetActionEndReason.completed && action != null
        ? _completionRetention[action]!
        : const _CompletionRetention();
    _activePlan = null;
    _handler = null;
    _context = null;
    if (!retention.target) _target = null;
    if (!retention.payload) _payload = null;
    _totalElapsed = Duration.zero;
    _phaseElapsed = Duration.zero;
    _lastEndReason = reason;
  }

  PetActionTickResult tick(PetActionContext context, Duration elapsed) =>
      _handler?.tick(context, elapsed) ?? PetActionTickResult.running;
}

Map<PetRuntimeAction, PetActionHandler Function()> _validateFactories(
  Iterable<MapEntry<PetRuntimeAction, PetActionHandler Function()>> entries,
) {
  final result = <PetRuntimeAction, PetActionHandler Function()>{};
  for (final entry in entries) {
    if (result.containsKey(entry.key)) {
      throw ArgumentError('duplicate handler factory: ${entry.key.name}');
    }
    result[entry.key] = entry.value;
  }
  if (result.length != PetRuntimeAction.values.length ||
      !result.keys.toSet().containsAll(PetRuntimeAction.values)) {
    throw ArgumentError(
      'handler registry must contain exactly one factory per PetRuntimeAction',
    );
  }
  return Map.unmodifiable(result);
}

final _defaultHandlerFactories =
    <MapEntry<PetRuntimeAction, PetActionHandler Function()>>[
      const MapEntry(PetRuntimeAction.observeTarget, ObserveTargetAction.new),
      const MapEntry(PetRuntimeAction.catPawTest, CatPawTestAction.new),
      const MapEntry(PetRuntimeAction.dogProbe, DogProbeAction.new),
      const MapEntry(PetRuntimeAction.parrotProbe, ParrotProbeAction.new),
      const MapEntry(PetRuntimeAction.inspectMedia, InspectMediaAction.new),
      const MapEntry(PetRuntimeAction.chaseEmoji, ChaseEmojiAction.new),
      const MapEntry(PetRuntimeAction.jumpToPlatform, JumpToPlatformAction.new),
    ];

class _CompletionRetention {
  const _CompletionRetention({this.target = false, this.payload = false});

  final bool target;
  final bool payload;
}

const _completionRetention = <PetRuntimeAction, _CompletionRetention>{
  PetRuntimeAction.jumpToPlatform: _CompletionRetention(target: true),
  PetRuntimeAction.chaseEmoji: _CompletionRetention(
    target: true,
    payload: true,
  ),
  PetRuntimeAction.inspectMedia: _CompletionRetention(
    target: true,
    payload: true,
  ),
  PetRuntimeAction.observeTarget: _CompletionRetention(),
  PetRuntimeAction.catPawTest: _CompletionRetention(
    target: true,
    payload: true,
  ),
  PetRuntimeAction.dogProbe: _CompletionRetention(target: true, payload: true),
  PetRuntimeAction.parrotProbe: _CompletionRetention(
    target: true,
    payload: true,
  ),
};
