import 'pet_behavior_catalog.dart';
import 'pet_behavior_runtime.dart';

/// Stateless eligibility policy for catalog behavior triggers.
class PetBehaviorTriggerMatcher {
  const PetBehaviorTriggerMatcher._();

  static bool matches({
    required PetBehaviorTrigger trigger,
    required Iterable<PetBehaviorAction> profileActions,
    required PetBehaviorStimulus stimulus,
  }) {
    if (trigger.stimulus != stimulus.stimulusType) return false;
    if (trigger.petType != null && trigger.petType != stimulus.petType) {
      return false;
    }
    if (!profileActions.contains(trigger.action)) return false;

    final definition = PetBehaviorCatalog.actionDefinitions[trigger.action];
    if (definition == null) return false;
    return definition.supportedStimulusTypes.contains(stimulus.stimulusType) &&
        definition.supportedContentKinds.contains(stimulus.contentKind) &&
        definition.supportedTargetKinds.contains(stimulus.targetKind);
  }
}
