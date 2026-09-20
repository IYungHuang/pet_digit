import 'dart:math' as math;
import 'dart:ui';
import '../pet_action_plan.dart';
import '../pet_effects.dart';
import '../pet_world.dart';
import 'pet_action_context.dart';
import 'pet_action_handler.dart';

final class ChaseEmojiAction extends PetActionHandlerBase {
  @override
  PetRuntimeAction get action => PetRuntimeAction.chaseEmoji;
  @override
  void start(PetActionContext c, PetActionPlan p) {
    c.state = PetState.pounce;
    final center = c.target!.bounds.center,
        dir = center.dx >= c.position.dx ? 1.0 : -1.0;
    c.toy = BouncingEmojiToy(
      emoji: p.payload is String && (p.payload! as String).isNotEmpty
          ? p.payload! as String
          : '👋',
      start: center,
      groundY: math.max(c.position.dy + 70, c.target!.bounds.bottom + 40),
      direction: dir,
    );
    c.frameIndex = 0;
  }

  @override
  PetActionTickResult tick(PetActionContext c, Duration e) {
    final toy = c.toy;
    if (toy == null || toy.isFinished) {
      c.state = PetState.idle;
      c.resetPatrolClock();
      c.complete();
      return PetActionTickResult.complete;
    }
    final x = (toy.position.dx - 32 * toy.direction).clamp(16.0, 310.0),
        y = toy.position.dy - 44,
        dx = x - c.position.dx,
        dy = y - c.position.dy,
        dist = math.sqrt(dx * dx + dy * dy),
        dt = e.inMilliseconds / 1000;
    if (dist > 15 && !toy.isCaught) {
      c.state = PetState.run;
      c.direction = dx >= 0 ? 1 : -1;
      c.position = Offset(
        (c.position.dx + dx / dist * 190 * dt).clamp(16, 310),
        (c.position.dy + dy / dist * 190 * dt).clamp(16, 800),
      );
      if (c.dustTimer > .08) {
        c.dustTimer = 0;
        c.spawnDust(c.position.translate(c.direction > 0 ? 12 : 44, 52));
      }
      c.footsteps(e, isRunning: true);
      c.frameIndex = (c.totalElapsed.inMilliseconds / 120).floor() % 2;
    } else {
      toy.isCaught = true;
      c.state = PetState.pounce;
      c.frameIndex = (c.totalElapsed.inMilliseconds / 200).floor().clamp(0, 1);
      if (c.totalElapsed.inMilliseconds > 1200) {
        c.state = PetState.idle;
        c.resetPatrolClock();
        c.toy = null;
        c.complete();
        return PetActionTickResult.complete;
      }
    }
    return PetActionTickResult.running;
  }
}
