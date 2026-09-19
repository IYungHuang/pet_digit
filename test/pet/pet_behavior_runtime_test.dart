import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/pet/domain/pet_behavior_catalog.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_runtime.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_content_kind.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';

void main() {
  test('selection separates catalog capability from execution status', () {
    const selection = PetBehaviorSelection(
      action: PetBehaviorAction.sniffBubble,
      targetId: 'm1',
      capability: PetBehaviorCapability.degraded,
      reason: 'observe fallback',
    );

    expect(selection.capability, PetBehaviorCapability.degraded);
  });

  test('stimulus preserves normalized target data', () {
    const stimulus = PetBehaviorStimulus(
      stimulusType: PetStimulusType.userTap,
      petType: PetType.cat,
      targetId: 'm1',
      targetKind: WorldObjectKind.emojiToy,
      contentKind: PetNormalizedContentKind.emoji,
      payload: '😺',
    );

    expect(stimulus.stimulusType, PetStimulusType.userTap);
    expect(stimulus.petType, PetType.cat);
    expect(stimulus.targetId, 'm1');
    expect(stimulus.targetKind, WorldObjectKind.emojiToy);
    expect(stimulus.contentKind, PetNormalizedContentKind.emoji);
    expect(stimulus.payload, '😺');
  });

  test('capability and execution status use separate complete enums', () {
    expect(PetBehaviorCapability.values, [
      PetBehaviorCapability.native,
      PetBehaviorCapability.degraded,
      PetBehaviorCapability.unsupported,
    ]);
    expect(PetBehaviorExecutionStatus.values, [
      PetBehaviorExecutionStatus.executed,
      PetBehaviorExecutionStatus.fallback,
      PetBehaviorExecutionStatus.ignored,
    ]);
    expect(
      PetBehaviorCapability.degraded,
      isNot(isA<PetBehaviorExecutionStatus>()),
    );
  });

  test('action definition exposes explicit runtime metadata', () {
    const definition = PetActionDefinition(
      action: PetBehaviorAction.sniffBubble,
      category: PetBehaviorCategory.investigate,
      animationKey: 'sniff_bubble',
      supportedStimulusTypes: [
        PetStimulusType.userTap,
        PetStimulusType.newMessageBubble,
      ],
      supportedContentKinds: [
        PetNormalizedContentKind.text,
        PetNormalizedContentKind.emoji,
      ],
      supportedTargetKinds: [
        WorldObjectKind.platform,
        WorldObjectKind.emojiToy,
      ],
      capability: PetBehaviorCapability.degraded,
    );

    expect(definition.supportedStimulusTypes, [
      PetStimulusType.userTap,
      PetStimulusType.newMessageBubble,
    ]);
    expect(definition.supportedContentKinds, [
      PetNormalizedContentKind.text,
      PetNormalizedContentKind.emoji,
    ]);
    expect(definition.supportedTargetKinds, [
      WorldObjectKind.platform,
      WorldObjectKind.emojiToy,
    ]);
    expect(definition.capability, PetBehaviorCapability.degraded);
  });

  test('action definition defaults to safe unsupported metadata', () {
    const definition = PetActionDefinition(
      action: PetBehaviorAction.sniffBubble,
      category: PetBehaviorCategory.investigate,
      animationKey: 'sniff_bubble',
    );

    expect(definition.supportedStimulusTypes, isEmpty);
    expect(definition.supportedContentKinds, isEmpty);
    expect(definition.supportedTargetKinds, isEmpty);
    expect(definition.capability, PetBehaviorCapability.unsupported);
  });
}
