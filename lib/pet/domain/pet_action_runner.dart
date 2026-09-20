import 'pet_action_plan.dart';
import 'pet_world.dart';

enum PetActionEndReason {
  completed,
  replaced,
  worldReset,
  petChanged,
  targetRemoved,
}

/// Owns action identity, live compatibility bindings, and action clocks.
///
/// Timeline behavior remains in [PetWorldController] until handler extraction.
class PetActionRunner {
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

  void start(PetActionPlan plan, PetInteractable target) {
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
    final action = _activePlan?.runtimeAction;
    final retention = reason == PetActionEndReason.completed && action != null
        ? _completionRetention[action]!
        : const _CompletionRetention();
    _activePlan = null;
    if (!retention.target) _target = null;
    if (!retention.payload) _payload = null;
    _totalElapsed = Duration.zero;
    _phaseElapsed = Duration.zero;
    _lastEndReason = reason;
  }
}

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
