import 'dart:math' as math;
import 'dart:ui';
import '../pet_action_plan.dart';
import '../pet_world.dart';
import 'pet_action_context.dart';
import 'pet_action_handler.dart';

final class JumpToPlatformAction extends PetActionHandlerBase {
  Offset _start = Offset.zero, _target = Offset.zero;
  final double _duration = .55;
  double _arc = 45;
  @override
  PetRuntimeAction get action => PetRuntimeAction.jumpToPlatform;
  Offset _landing(PetActionContext c, Rect b) {
    final max = math.max(b.left + 4, b.right - 56).toDouble();
    return Offset((b.center.dx - 32).clamp(b.left + 4, max), b.top - 52);
  }

  @override
  void start(PetActionContext c, PetActionPlan p) {
    _start = c.position;
    _target = _landing(c, c.target!.bounds);
    c.direction = _target.dx >= c.position.dx ? 1 : -1;
    _arc = math.max(35, (_start.dy - _target.dy).abs() * .4 + 25);
    c.state = PetState.jump;
    c.frameIndex = 0;
    c.currentSurfaceY = _start.dy + 52;
    c.heightAboveSurface = 0;
  }

  @override
  PetActionTickResult tick(PetActionContext c, Duration e) {
    final t = c.target;
    if (t == null) {
      c.state = PetState.idle;
      c.complete(PetActionEndReason.targetRemoved);
      return PetActionTickResult.complete;
    }
    _target = _landing(c, t.bounds);
    final p = (c.totalElapsed.inMilliseconds / 1000 / _duration).clamp(
          0.0,
          1.0,
        ),
        x = _start.dx + (_target.dx - _start.dx) * p,
        y = _start.dy + (_target.dy - _start.dy) * p,
        arc = 4 * _arc * p * (1 - p);
    c.position = Offset(x, y - arc);
    c.currentSurfaceY =
        _start.dy + 52 + ((_target.dy + 52) - (_start.dy + 52)) * p;
    c.heightAboveSurface = arc;
    c.frameIndex = (c.totalElapsed.inMilliseconds / 200).floor().clamp(0, 1);
    if (p >= 1) {
      c.currentPlatform = t as PetBoundedInteractable?;
      c.state = PetState.idle;
      c.resetPatrolClock();
      if (c.currentPlatform != null) {
        c.bubbleImpulse(c.currentPlatform!.id, 160);
      }
      c.position = Offset(
        _target.dx,
        _target.dy +
            (c.currentPlatform == null
                ? 0
                : c.bubbleDeflection(c.currentPlatform!.id)),
      );
      c.spawnDust(c.position.translate(16, 52));
      c.spawnDust(c.position.translate(40, 52));
      c.heightAboveSurface = 0;
      c.complete();
      return PetActionTickResult.complete;
    }
    return PetActionTickResult.running;
  }
}
