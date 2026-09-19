import 'pet_behavior_catalog.dart';
import 'pet_behavior_runtime.dart';
import 'pet_message_target.dart';
import 'pet_world.dart';

/// Creates immutable behavior stimuli from normalized message targets.
class PetBehaviorNormalizer {
  const PetBehaviorNormalizer._();

  static PetBehaviorStimulus fromTarget(
    PetMessageTarget target,
    PetStimulusType stimulusType, {
    required PetType petType,
  }) => PetBehaviorStimulus(
    stimulusType: stimulusType,
    petType: petType,
    targetId: target.id,
    targetKind: target.kind,
    contentKind: target.contentKind,
    payload: target.payload,
  );
}
