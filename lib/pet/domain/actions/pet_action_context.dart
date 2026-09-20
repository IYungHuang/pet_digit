import 'dart:ui';

import 'pet_action_handler.dart' show PetActionEndReason;
import '../pet_effects.dart';
import '../pet_world.dart';

abstract interface class PetActionContext {
  PetInteractable? get target;
  Duration get totalElapsed;
  Duration get phaseElapsed;
  Duration get previousTotalElapsed;
  Duration get previousPhaseElapsed;
  Offset get position;
  set position(Offset value);
  PetState get state;
  set state(PetState value);
  double get direction;
  set direction(double value);
  set frameIndex(int value);
  Size get viewportSize;
  PetBoundedInteractable? get currentPlatform;
  set currentPlatform(PetBoundedInteractable? value);
  double get currentSurfaceY;
  set currentSurfaceY(double value);
  double get heightAboveSurface;
  set heightAboveSurface(double value);
  BouncingEmojiToy? get toy;
  set toy(BouncingEmojiToy? value);
  double get dustTimer;
  set dustTimer(double value);
  Offset messageSidePosition(
    PetInteractable target, {
    required bool useRightSide,
  });
  bool usesRightSideOf(Rect bounds);
  double bubbleDeflection(String id);
  void bubbleImpulse(String id, double force);
  void footsteps(Duration elapsed, {required bool isRunning});
  void spawnDust(Offset position);
  void spawnHeart(Offset position);
  void beginPhase();
  void resetPatrolClock();
  void complete([PetActionEndReason reason = PetActionEndReason.completed]);
}
