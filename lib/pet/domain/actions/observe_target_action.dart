import 'dart:math' as math;

import '../pet_action_plan.dart';
import '../pet_world.dart';
import 'pet_action_context.dart';
import 'pet_action_handler.dart';

final class ObserveTargetAction extends PetActionHandlerBase {
  bool _walkToward = false;
  @override
  PetRuntimeAction get action => PetRuntimeAction.observeTarget;
  @override
  void start(PetActionContext c, PetActionPlan p) {
    _walkToward = p.walkToward;
    c.state = _walkToward ? PetState.walk : PetState.observe;
    c.frameIndex = 0;
  }

  @override
  PetActionTickResult tick(PetActionContext c, Duration elapsed) {
    final target = c.target;
    if (target == null) {
      c.state = PetState.idle;
      c.complete(PetActionEndReason.targetRemoved);
      return PetActionTickResult.complete;
    }
    if (!_walkToward) {
      c.state = PetState.observe;
      c.frameIndex = (c.phaseElapsed.inMilliseconds / 350).floor() % 2;
      if (c.phaseElapsed.inMilliseconds >= 900) {
        c.state = PetState.idle;
        c.complete();
        return PetActionTickResult.complete;
      }
      return PetActionTickResult.running;
    }
    final destination = c.messageSidePosition(
      target,
      useRightSide: c.usesRightSideOf(target.bounds),
    );
    final dx = destination.dx - c.position.dx,
        dy = destination.dy - c.position.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance <= 12 || 90 * elapsed.inMilliseconds / 1000 >= distance) {
      if (distance > 12) c.position = destination;
      _walkToward = false;
      c.state = PetState.observe;
      c.frameIndex = 0;
      c.beginPhase();
      return PetActionTickResult.running;
    }
    c.state = PetState.walk;
    c.direction = dx >= 0 ? 1 : -1;
    final step = 90 * elapsed.inMilliseconds / 1000;
    c.position = c.position.translate(
      dx / distance * step,
      dy / distance * step,
    );
    c.footsteps(elapsed, isRunning: false);
    c.frameIndex = (c.totalElapsed.inMilliseconds / 150).floor() % 4;
    return PetActionTickResult.running;
  }
}
