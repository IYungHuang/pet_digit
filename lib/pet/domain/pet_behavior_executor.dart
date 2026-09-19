import 'pet_behavior_catalog.dart';
import 'pet_behavior_runtime.dart';
import 'pet_message_target.dart';
import 'pet_world.dart';

/// Observable outcome of running one selected catalog behavior.
class PetBehaviorExecutionResult {
  const PetBehaviorExecutionResult({
    required this.status,
    required this.action,
    required this.targetId,
    required this.reason,
  });

  final PetBehaviorExecutionStatus status;
  final PetBehaviorAction? action;
  final String targetId;
  final String reason;
}

/// Maps selected catalog behaviors to runtime sequences without inferring data
/// from concrete message target classes.
class PetBehaviorExecutor {
  const PetBehaviorExecutor(this._runtime);

  final PetBehaviorRuntime _runtime;

  PetBehaviorExecutionResult execute(
    PetBehaviorSelection selection,
    PetMessageTarget target,
  ) {
    if (selection.targetId != target.id) {
      return _ignored(selection, target, 'selection target mismatch');
    }
    if (!target.hasMeasuredBounds) {
      return _ignored(selection, target, 'target bounds are not ready');
    }

    switch (selection.action) {
      case PetBehaviorAction.nosePawBump:
        if (selection.stimulusType == PetStimulusType.userTap &&
            target.kind == WorldObjectKind.platform) {
          _runtime.startJumpToPlatform(target);
          return _executed(selection, target, 'platform jump');
        }
        return _observeFallback(
          selection,
          target,
          'nosePawBump needs platform',
        );
      case PetBehaviorAction.headBuntRub:
      case PetBehaviorAction.beakTouch:
        if (target.kind == WorldObjectKind.platform) {
          _runtime.startJumpToPlatform(target);
          return _fallback(selection, target, 'platform jump fallback');
        }
        return _observeFallback(selection, target, 'platform target required');
      case PetBehaviorAction.runChase:
      case PetBehaviorAction.pounce:
        if (target.kind == WorldObjectKind.emojiToy) {
          _runtime.startChaseEmoji(target, payload: target.payload);
          return _executed(selection, target, 'emoji chase');
        }
        return _observeFallback(selection, target, 'emoji target required');
      case PetBehaviorAction.flyFlap:
        if (target.kind == WorldObjectKind.emojiToy) {
          _runtime.startChaseEmoji(target, payload: target.payload);
          return _fallback(selection, target, 'emoji chase fallback');
        }
        return _observeFallback(selection, target, 'emoji target required');
      case PetBehaviorAction.sniffBubble:
        if (target.kind == WorldObjectKind.animatedToy) {
          _runtime.startInspectGif(target, payload: target.payload);
          return _fallback(selection, target, 'observe fallback');
        }
        return _observeFallback(selection, target, 'media target required');
      case PetBehaviorAction.novelObjectNoseProbe:
        if (target.kind == WorldObjectKind.animatedToy) {
          _runtime.startDogProbe(target);
          return _executed(selection, target, 'native dog media probe');
        }
        return _observeFallback(selection, target, 'media target required');
      case PetBehaviorAction.headTiltFocus:
      case PetBehaviorAction.sniffWhiskerScan:
      case PetBehaviorAction.headTiltEyeFocus:
        if (target.kind == WorldObjectKind.animatedToy) {
          _runtime.startInspectGif(target, payload: target.payload);
          return _fallback(selection, target, 'observe fallback');
        }
        return _observeFallback(selection, target, 'observe fallback');
      case PetBehaviorAction.circleSniff:
        _runtime.startObserveTarget(target, walkToward: true);
        return _fallback(selection, target, 'walk-toward observe fallback');
      case PetBehaviorAction.pawTest:
        if (target.kind == WorldObjectKind.animatedToy) {
          _runtime.startPawTest(target);
          return _executed(selection, target, 'native paw test');
        }
        return _observeFallback(selection, target, 'media target required');
      case PetBehaviorAction.batPounce:
        if (target.kind == WorldObjectKind.emojiToy) {
          _runtime.startChaseEmoji(target, payload: target.payload);
          return _fallback(selection, target, 'emoji chase fallback');
        }
        return _observeFallback(selection, target, 'emoji target required');
      case PetBehaviorAction.hidePeek:
      case PetBehaviorAction.beakManipulate:
        return _observeFallback(
          selection,
          target,
          'observe fallback; no equivalent runtime',
        );
      case PetBehaviorAction.beakProbe:
        if (target.kind == WorldObjectKind.animatedToy) {
          _runtime.startParrotProbe(target);
          return _executed(selection, target, 'native parrot media probe');
        }
        return _observeFallback(selection, target, 'media target required');
      case PetBehaviorAction.flyBack:
        return _ignored(
          selection,
          target,
          'flyBack has no safe runtime mapping',
        );
      case PetBehaviorAction.approachArc:
      case PetBehaviorAction.approachStopStart:
      case PetBehaviorAction.approachLowSilent:
      case PetBehaviorAction.approachSideways:
        _runtime.startObserveTarget(target, walkToward: true);
        return _fallback(selection, target, 'light approach fallback');
      default:
        return _ignored(
          selection,
          target,
          'unsupported action ${selection.action.name}',
        );
    }
  }

  PetBehaviorExecutionResult _observeFallback(
    PetBehaviorSelection selection,
    PetMessageTarget target,
    String reason,
  ) {
    _runtime.startObserveTarget(target, walkToward: false);
    return _fallback(selection, target, reason);
  }

  PetBehaviorExecutionResult _executed(
    PetBehaviorSelection selection,
    PetMessageTarget target,
    String reason,
  ) => PetBehaviorExecutionResult(
    status: PetBehaviorExecutionStatus.executed,
    action: selection.action,
    targetId: target.id,
    reason: reason,
  );

  PetBehaviorExecutionResult _fallback(
    PetBehaviorSelection selection,
    PetMessageTarget target,
    String reason,
  ) => PetBehaviorExecutionResult(
    status: PetBehaviorExecutionStatus.fallback,
    action: selection.action,
    targetId: target.id,
    reason: reason,
  );

  PetBehaviorExecutionResult _ignored(
    PetBehaviorSelection? selection,
    PetMessageTarget target,
    String reason,
  ) => PetBehaviorExecutionResult(
    status: PetBehaviorExecutionStatus.ignored,
    action: selection?.action,
    targetId: target.id,
    reason: reason,
  );
}
