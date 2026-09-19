import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/pet/domain/pet_behavior_catalog.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_normalizer.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_runtime.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_selector.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_trigger_matcher.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_content_kind.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_target.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';

void main() {
  const selector = PetBehaviorSelector();

  test('normalizer preserves explicit species and target data', () {
    final target = _target(
      id: 'emoji-1',
      kind: WorldObjectKind.emojiToy,
      contentKind: PetNormalizedContentKind.emoji,
      payload: '🐕',
    );

    final stimulus = PetBehaviorNormalizer.fromTarget(
      target,
      PetStimulusType.userTap,
      petType: PetType.cat,
    );

    expect(stimulus.stimulusType, PetStimulusType.userTap);
    expect(stimulus.petType, PetType.cat);
    expect(stimulus.targetId, 'emoji-1');
    expect(stimulus.targetKind, WorldObjectKind.emojiToy);
    expect(stimulus.contentKind, PetNormalizedContentKind.emoji);
    expect(stimulus.payload, '🐕');
  });

  test('user tap text selects legacy platform action', () {
    final selection = selector.select(
      _stimulus(
        PetType.corgi,
        PetStimulusType.userTap,
        WorldObjectKind.platform,
        PetNormalizedContentKind.text,
      ),
    );

    expect(selection?.action, PetBehaviorAction.nosePawBump);
    expect(selection?.capability, PetBehaviorCapability.native);
  });

  test('user tap emoji selects emoji-compatible action', () {
    final selection = selector.select(
      _stimulus(
        PetType.corgi,
        PetStimulusType.userTap,
        WorldObjectKind.emojiToy,
        PetNormalizedContentKind.emoji,
      ),
    );

    expect(selection?.action, PetBehaviorAction.runChase);
    expect(selection?.capability, PetBehaviorCapability.native);
  });

  test('user tap media selects inspect-compatible action', () {
    final selection = selector.select(
      _stimulus(
        PetType.corgi,
        PetStimulusType.userTap,
        WorldObjectKind.animatedToy,
        PetNormalizedContentKind.gif,
      ),
    );

    expect(selection?.action, PetBehaviorAction.sniffBubble);
    expect(selection?.capability, PetBehaviorCapability.degraded);
  });

  test('legacy tap behavior remains target-compatible for every species', () {
    final catText = selector.select(
      _stimulus(
        PetType.cat,
        PetStimulusType.userTap,
        WorldObjectKind.platform,
        PetNormalizedContentKind.text,
      ),
    );
    final catEmoji = selector.select(
      _stimulus(
        PetType.cat,
        PetStimulusType.userTap,
        WorldObjectKind.emojiToy,
        PetNormalizedContentKind.emoji,
      ),
    );
    final catMedia = selector.select(
      _stimulus(
        PetType.cat,
        PetStimulusType.userTap,
        WorldObjectKind.animatedToy,
        PetNormalizedContentKind.image,
      ),
    );
    final parrotText = selector.select(
      _stimulus(
        PetType.parrot,
        PetStimulusType.userTap,
        WorldObjectKind.platform,
        PetNormalizedContentKind.text,
      ),
    );
    final parrotEmoji = selector.select(
      _stimulus(
        PetType.parrot,
        PetStimulusType.userTap,
        WorldObjectKind.emojiToy,
        PetNormalizedContentKind.emoji,
      ),
    );
    final parrotMedia = selector.select(
      _stimulus(
        PetType.parrot,
        PetStimulusType.userTap,
        WorldObjectKind.animatedToy,
        PetNormalizedContentKind.video,
      ),
    );

    expect(catText?.action, PetBehaviorAction.headBuntRub);
    expect(catEmoji?.action, PetBehaviorAction.pounce);
    expect(catMedia?.action, PetBehaviorAction.sniffWhiskerScan);
    expect(parrotText?.action, PetBehaviorAction.beakTouch);
    expect(parrotEmoji?.action, PetBehaviorAction.flyFlap);
    expect(parrotMedia?.action, PetBehaviorAction.headTiltEyeFocus);
  });

  test('same new-message stimulus selects species-specific candidates', () {
    final corgi = selector.select(
      _stimulus(
        PetType.corgi,
        PetStimulusType.newMessageBubble,
        WorldObjectKind.platform,
        PetNormalizedContentKind.text,
      ),
    );
    final cat = selector.select(
      _stimulus(
        PetType.cat,
        PetStimulusType.newMessageBubble,
        WorldObjectKind.platform,
        PetNormalizedContentKind.text,
      ),
    );
    final parrot = selector.select(
      _stimulus(
        PetType.parrot,
        PetStimulusType.newMessageBubble,
        WorldObjectKind.platform,
        PetNormalizedContentKind.text,
      ),
    );

    expect(corgi?.action, PetBehaviorAction.approachArc);
    expect(cat?.action, PetBehaviorAction.approachLowSilent);
    expect(parrot?.action, PetBehaviorAction.approachSideways);
    expect(corgi?.capability, PetBehaviorCapability.unsupported);
    expect(cat?.capability, PetBehaviorCapability.unsupported);
    expect(parrot?.capability, PetBehaviorCapability.unsupported);
  });

  test('user tap and new-message candidates remain source-isolated', () {
    final tap = selector.select(
      _stimulus(
        PetType.corgi,
        PetStimulusType.userTap,
        WorldObjectKind.platform,
        PetNormalizedContentKind.text,
      ),
    );
    final newMessage = selector.select(
      _stimulus(
        PetType.corgi,
        PetStimulusType.newMessageBubble,
        WorldObjectKind.platform,
        PetNormalizedContentKind.text,
      ),
    );

    expect(tap?.action, PetBehaviorAction.nosePawBump);
    expect(newMessage?.action, PetBehaviorAction.approachArc);
  });

  test('trigger matcher rejects a mismatched declared stimulus', () {
    const trigger = PetBehaviorTrigger(
      stimulus: PetStimulusType.newMessageBubble,
      action: PetBehaviorAction.nosePawBump,
      petType: PetType.corgi,
    );

    final matches = PetBehaviorTriggerMatcher.matches(
      trigger: trigger,
      profileActions: const [PetBehaviorAction.nosePawBump],
      stimulus: _stimulus(
        PetType.corgi,
        PetStimulusType.userTap,
        WorldObjectKind.platform,
        PetNormalizedContentKind.text,
      ),
    );

    expect(matches, isFalse);
  });

  test('wrong target kind returns no candidate', () {
    final selection = selector.select(
      _stimulus(
        PetType.corgi,
        PetStimulusType.userTap,
        WorldObjectKind.animatedToy,
        PetNormalizedContentKind.text,
      ),
    );

    expect(selection, isNull);
  });

  test('equal-priority candidates use catalog declaration order', () {
    final selection = selector.select(
      _stimulus(
        PetType.corgi,
        PetStimulusType.newMessageBubble,
        WorldObjectKind.platform,
        PetNormalizedContentKind.text,
      ),
    );

    expect(selection?.action, PetBehaviorAction.approachArc);
  });
}

PetBehaviorStimulus _stimulus(
  PetType petType,
  PetStimulusType stimulusType,
  WorldObjectKind targetKind,
  PetNormalizedContentKind contentKind,
) => PetBehaviorStimulus(
  stimulusType: stimulusType,
  petType: petType,
  targetId: 'target-1',
  targetKind: targetKind,
  contentKind: contentKind,
  payload: 'payload',
);

PetMessageTarget _target({
  required String id,
  required WorldObjectKind kind,
  required PetNormalizedContentKind contentKind,
  required Object? payload,
}) => PetMessageTarget(
  id: id,
  kind: kind,
  contentKind: contentKind,
  payload: payload,
  messageText: '$payload',
);
