import '../pet_action_plan.dart';
import 'pet_action_context.dart';

enum PetActionTickResult { running, complete }

enum PetActionEndReason {
  completed,
  replaced,
  worldReset,
  petChanged,
  targetRemoved,
}

abstract interface class PetActionHandler {
  PetRuntimeAction get action;
  void start(PetActionContext context, PetActionPlan plan);
  PetActionTickResult tick(PetActionContext context, Duration elapsed);
  void cancel(PetActionContext context, PetActionEndReason reason);
}

abstract base class PetActionHandlerBase implements PetActionHandler {
  @override
  void cancel(PetActionContext context, PetActionEndReason reason) {}

  PetActionTickResult publish(PetActionContext context, int frame) {
    context.frameIndex = frame;
    return PetActionTickResult.running;
  }
}
