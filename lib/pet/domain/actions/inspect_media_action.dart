import 'dart:math' as math;
import '../pet_action_plan.dart';
import '../pet_world.dart';
import 'pet_action_context.dart';
import 'pet_action_handler.dart';

final class InspectMediaAction extends PetActionHandlerBase {
  bool _right = false;
  @override
  PetRuntimeAction get action => PetRuntimeAction.inspectMedia;
  @override
  void start(PetActionContext c, PetActionPlan p) {
    _right = c.usesRightSideOf(c.target!.bounds);
    c.state = PetState.observe;
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
        ms = c.totalElapsed.inMilliseconds;
    if (ms < 600) {
      c.state = PetState.observe;
      c.direction = d.dx >= c.position.dx ? 1 : -1;
    } else if (ms < 1200) {
      c.state = PetState.observe;
      if (c.dustTimer > .25) {
        c.dustTimer = 0;
        c.spawnHeart(c.position.translate(32, 8));
      }
    } else if (ms < 1900) {
      c.state = PetState.run;
      final dx = d.dx - c.position.dx,
          dy = d.dy - c.position.dy,
          dist = math.sqrt(dx * dx + dy * dy);
      if (dist > 6) {
        c.direction = dx >= 0 ? 1 : -1;
        final dt = e.inMilliseconds / 1000;
        c.position = c.position.translate(
          dx / dist * 140 * dt,
          dy / dist * 140 * dt,
        );
        c.footsteps(e, isRunning: true);
      }
    } else if (ms < 2800) {
      c.state = PetState.pounce;
      c.position = d;
      if (c.dustTimer > .2) {
        c.dustTimer = 0;
        c.spawnHeart(c.position.translate(20, -10));
      }
    } else {
      c.state = PetState.idle;
      c.resetPatrolClock();
      c.complete();
      return PetActionTickResult.complete;
    }
    c.frameIndex = switch (c.state) {
      PetState.observe => (ms / 350).floor() % 2,
      PetState.run => (ms / 120).floor() % 2,
      PetState.pounce => (ms / 200).floor().clamp(0, 1),
      _ => 0,
    };
    return PetActionTickResult.running;
  }
}
