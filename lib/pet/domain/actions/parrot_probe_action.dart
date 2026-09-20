import 'dart:ui';
import '../pet_action_plan.dart';
import '../pet_world.dart';
import 'pet_action_context.dart';
import 'pet_action_handler.dart';

final class ParrotProbeAction extends PetActionHandlerBase {
  Offset _start = Offset.zero;
  bool _right = false, _first = false, _second = false;
  @override
  PetRuntimeAction get action => PetRuntimeAction.parrotProbe;
  double _ease(double v) {
    final t = v.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  @override
  void start(PetActionContext c, PetActionPlan p) {
    final t = c.target!;
    _start = c.position;
    _right = c.usesRightSideOf(t.bounds);
    final d = c.messageSidePosition(t, useRightSide: _right);
    c.direction = d.dx >= c.position.dx ? 1 : -1;
    c.state = PetState.parrotProbe;
    c.frameIndex = 0;
  }

  @override
  PetActionTickResult tick(PetActionContext c, Duration e) {
    final t = c.target;
    if (t == null) {
      c.state = PetState.idle;
      c.complete(PetActionEndReason.targetRemoved);
      return PetActionTickResult.complete;
    }
    final d = c.messageSidePosition(t, useRightSide: _right),
        ms = c.totalElapsed.inMilliseconds,
        prev = c.previousTotalElapsed.inMilliseconds;
    if (!_first && prev < 1700 && ms >= 1700) {
      _first = true;
      c.bubbleImpulse(t.id, 20);
    }
    if (!_second && prev < 2300 && ms >= 2300) {
      _second = true;
      c.bubbleImpulse(t.id, 14);
    }
    if (ms < 200) {
      c.position = _start;
    } else if (ms < 700) {
      final p = _ease((ms - 200) / 500);
      c.position = Offset.lerp(_start, d, p)!;
      c.direction = d.dx >= _start.dx ? 1 : -1;
    } else {
      c.position = d;
      c.direction = _right ? -1 : 1;
    }
    c.state = PetState.parrotProbe;
    c.frameIndex = ms < 200
        ? 0
        : ms < 450
        ? 1
        : ms < 700
        ? 2
        : ms < 1700
        ? 3
        : ms < 2300
        ? 4
        : 5;
    if (ms >= 2700) {
      c.state = PetState.idle;
      c.complete();
      return PetActionTickResult.complete;
    }
    return PetActionTickResult.running;
  }
}
