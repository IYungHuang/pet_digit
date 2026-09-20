import 'dart:ui';
import '../pet_action_plan.dart';
import '../pet_world.dart';
import 'pet_action_context.dart';
import 'pet_action_handler.dart';

final class CatPawTestAction extends PetActionHandlerBase {
  Offset _start = Offset.zero;
  bool _right = false;
  bool _first = false, _second = false;
  @override
  PetRuntimeAction get action => PetRuntimeAction.catPawTest;
  @override
  void start(PetActionContext c, PetActionPlan p) {
    final t = c.target!;
    _start = c.position;
    _right = c.usesRightSideOf(t.bounds);
    final d = c.messageSidePosition(t, useRightSide: _right);
    c.direction = d.dx >= c.position.dx ? 1 : -1;
    c.state = PetState.catStalk;
    c.frameIndex = 0;
  }

  double _ease(double v) {
    final t = v.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  @override
  PetActionTickResult tick(PetActionContext c, Duration elapsed) {
    final t = c.target;
    if (t == null) {
      c.state = PetState.idle;
      c.complete(PetActionEndReason.targetRemoved);
      return PetActionTickResult.complete;
    }
    final target = c.messageSidePosition(t, useRightSide: _right),
        ms = c.totalElapsed.inMilliseconds,
        prev = c.previousTotalElapsed.inMilliseconds;
    if (!_first && prev < 2000 && ms >= 2000) {
      _first = true;
      c.bubbleImpulse(t.id, 45);
    }
    if (!_second && prev < 2450 && ms >= 2450) {
      _second = true;
      c.bubbleImpulse(t.id, 32);
    }
    final stop = Offset.lerp(_start, target, .35)!;
    if (ms < 550) {
      c.position = _start;
      c.state = PetState.catStalk;
    } else if (ms < 1000) {
      final dx = target.dx - c.position.dx;
      if (dx.abs() > .001) c.direction = dx.isNegative ? -1 : 1;
      c.position = Offset.lerp(_start, stop, _ease((ms - 550) / 450))!;
      c.state = PetState.catStalk;
      c.footsteps(elapsed, isRunning: false);
    } else if (ms < 1300) {
      c.position = stop;
      c.state = PetState.catStalk;
    } else if (ms < 1700) {
      c.position = Offset.lerp(stop, target, _ease((ms - 1300) / 400))!;
      c.state = PetState.catStalk;
      c.footsteps(elapsed, isRunning: false);
    } else {
      c.position = target;
      c.direction = _right ? -1 : 1;
      c.state = PetState.pawTest;
    }
    c.frameIndex = ms < 1850
        ? 0
        : ms < 2000
        ? 1
        : ms < 2150
        ? 2
        : ms < 2300
        ? 3
        : ms < 2450
        ? 4
        : 5;
    if (ms >= 3000) {
      c.state = PetState.idle;
      c.resetPatrolClock();
      c.complete();
      return PetActionTickResult.complete;
    }
    return PetActionTickResult.running;
  }
}
