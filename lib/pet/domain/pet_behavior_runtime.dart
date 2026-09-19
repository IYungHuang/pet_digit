import 'pet_behavior_catalog.dart';
import 'pet_message_content_kind.dart';
import 'pet_world.dart';

/// Runtime support cataloged for a behavior action.
enum PetBehaviorCapability { native, degraded, unsupported }

/// Result produced when a selected behavior reaches runtime execution.
enum PetBehaviorExecutionStatus { executed, fallback, ignored }

/// Immutable event data used to select a catalog behavior.
class PetBehaviorStimulus {
  const PetBehaviorStimulus({
    required this.stimulusType,
    required this.petType,
    required this.targetId,
    required this.targetKind,
    required this.contentKind,
    required this.payload,
    this.sourceIdentity,
  });

  final PetStimulusType stimulusType;
  final PetType petType;
  final String targetId;
  final WorldObjectKind targetKind;
  final PetNormalizedContentKind contentKind;
  final Object? payload;

  /// Stable message source, independent of canonical target ID changes.
  /// Omitted only for legacy or standalone targets without source metadata.
  final ({String roomId, String clientId})? sourceIdentity;
}

/// Immutable catalog choice. Execution outcome remains separate.
class PetBehaviorSelection {
  const PetBehaviorSelection({
    required this.action,
    required this.stimulusType,
    required this.targetId,
    required this.capability,
    required this.reason,
  });

  final PetBehaviorAction action;
  final PetStimulusType stimulusType;
  final String targetId;
  final PetBehaviorCapability capability;
  final String reason;
}
