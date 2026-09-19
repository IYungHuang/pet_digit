import 'pet_behavior_catalog.dart';
import 'pet_behavior_runtime.dart';

/// Pure, deterministic catalog selector for normalized pet stimuli.
class PetBehaviorSelector {
  const PetBehaviorSelector();

  PetBehaviorSelection? select(PetBehaviorStimulus stimulus) {
    final profile = PetBehaviorCatalog.profiles[stimulus.petType];
    if (profile == null) return null;

    final triggers = switch (stimulus.stimulusType) {
      PetStimulusType.userTap => PetBehaviorCatalog.legacyTapTriggers,
      PetStimulusType.newMessageBubble =>
        PetBehaviorCatalog.novelObjectTriggers,
      _ => const <PetBehaviorTrigger>[],
    };
    final profileActions =
        stimulus.stimulusType == PetStimulusType.newMessageBubble
        ? profile.novelObjectActions
        : <PetBehaviorAction>[
            ...profile.actions,
            ...profile.novelObjectActions,
          ];

    PetBehaviorTrigger? selected;
    for (final trigger in triggers) {
      if (!_isCompatible(
        trigger: trigger,
        profileActions: profileActions,
        stimulus: stimulus,
      )) {
        continue;
      }
      if (selected == null || trigger.priority > selected.priority) {
        selected = trigger;
      }
    }
    if (selected == null) return null;

    final definition = PetBehaviorCatalog.actionDefinitions[selected.action]!;
    return PetBehaviorSelection(
      action: selected.action,
      targetId: stimulus.targetId,
      capability: definition.capability,
      reason: '${stimulus.stimulusType.name}:${selected.action.name}',
    );
  }

  bool _isCompatible({
    required PetBehaviorTrigger trigger,
    required List<PetBehaviorAction> profileActions,
    required PetBehaviorStimulus stimulus,
  }) {
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
