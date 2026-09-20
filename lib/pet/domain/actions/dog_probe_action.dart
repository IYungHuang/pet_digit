import 'dart:math' as math;
import 'dart:ui';
import '../pet_action_plan.dart';
import '../pet_world.dart';
import 'pet_action_context.dart';
import 'pet_action_handler.dart';

final class DogProbeAction extends PetActionHandlerBase {
  Offset _start = Offset.zero;
  bool _right = false, _first = false, _second = false;
  @override
  PetRuntimeAction get action => PetRuntimeAction.dogProbe;
  @override
  void start(PetActionContext c, PetActionPlan p) {
    final t = c.target!;
    _start = c.position;
    _right = c.usesRightSideOf(t.bounds);
    final d = c.messageSidePosition(t, useRightSide: _right);
    c.direction = d.dx >= c.position.dx ? 1 : -1;
    c.state = PetState.dogProbe;
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
    final d = c.messageSidePosition(t, useRightSide: _right),
        ms = c.totalElapsed.inMilliseconds,
        prev = c.previousTotalElapsed.inMilliseconds;
    if (!_first && prev < 1700 && ms >= 1700) {
      _first = true;
      c.bubbleImpulse(t.id, 24);
    }
    if (!_second && prev < 2300 && ms >= 2300) {
      _second = true;
      c.bubbleImpulse(t.id, 18);
    }
    if (ms < 200) {
      c.position = _start;
    } else if (ms < 1000) {
      final p = _ease((ms - 200) / 800);
      c.position = Offset.lerp(
        _start,
        d,
        p,
      )!.translate(0, -math.sin(math.pi * p) * 18);
      c.direction = d.dx >= _start.dx ? 1 : -1;
    } else {
      c.position = d;
      c.direction = _right ? -1 : 1;
    }
    c.state = PetState.dogProbe;
    c.frameIndex = ms < 200
        ? 0
        : ms < 650
        ? 1
        : ms < 1000
        ? 2
        : ms < 1700
        ? 3
        : ms < 2300
        ? 4
        : 5;
    if (ms >= 2800) {
      c.state = PetState.idle;
      c.complete();
      return PetActionTickResult.complete;
    }
    return PetActionTickResult.running;
  }
}
