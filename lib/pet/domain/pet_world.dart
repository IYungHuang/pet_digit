import 'dart:ui';

import '../../chat/domain/chat_models.dart';
import 'pet_action_plan.dart';

enum PetType { corgi, cat, parrot }

class PetConfig {
  const PetConfig({
    required this.type,
    required this.displayName,
    required this.avatarEmoji,
    required this.voiceGreeting,
    required this.pounceLabel,
    required this.observeLabel,
    required this.trailAsset,
    required this.isBird,
  });

  final PetType type;
  final String displayName;
  final String avatarEmoji;
  final String voiceGreeting;
  final String pounceLabel;
  final String observeLabel;
  final String trailAsset;
  final bool isBird;

  static const corgi = PetConfig(
    type: PetType.corgi,
    displayName: '阿福 (柯基)',
    avatarEmoji: '🐕',
    voiceGreeting: '汪！',
    pounceLabel: 'pounce!',
    observeLabel: 'watching',
    trailAsset: 'assets/pets/corgi_paw.png',
    isBird: false,
  );

  static const cat = PetConfig(
    type: PetType.cat,
    displayName: '咪咪 (貓咪)',
    avatarEmoji: '🐱',
    voiceGreeting: '喵～',
    pounceLabel: 'pounce!',
    observeLabel: 'watching',
    trailAsset: 'assets/pets/cat_paw.png',
    isBird: false,
  );

  static const parrot = PetConfig(
    type: PetType.parrot,
    displayName: '波波 (鸚鵡)',
    avatarEmoji: '🦜',
    voiceGreeting: '好耶！',
    pounceLabel: 'dive!',
    observeLabel: 'dancing 🎵',
    trailAsset: 'assets/pets/parrot_paw.png',
    isBird: true,
  );

  static PetConfig of(PetType type) {
    switch (type) {
      case PetType.corgi:
        return corgi;
      case PetType.cat:
        return cat;
      case PetType.parrot:
        return parrot;
    }
  }
}

enum PetState {
  idle,
  walk,
  run,
  jump,
  observe,
  pounce,
  catStalk,
  pawTest,
  dogProbe,
  parrotProbe,
}

enum WorldObjectKind { platform, emojiToy, animatedToy }

class PetEvent {
  const PetEvent.tap();
}

abstract interface class PetInteractable {
  String get id;
  WorldObjectKind get kind;
  Offset get position;
  Rect get bounds;
  PetState interactionFor(PetEvent event);
}

abstract interface class PetBoundedInteractable implements PetInteractable {
  /// Whether bounds came from an actual layout measurement.
  bool get hasMeasuredBounds;

  void updateBounds(Rect newBounds);
}

/// Runtime commands used by catalog behavior execution.
///
/// Controller remains owner of animation state and effects. Executor only
/// selects an explicit compatible runtime sequence.
abstract interface class PetBehaviorRuntime {
  void startAction(PetActionPlan plan, PetInteractable target);
}

class MessageWorldObject implements PetBoundedInteractable {
  MessageWorldObject({
    required this.message,
    required this.position,
    Rect? bounds,
  }) : bounds = bounds ?? Rect.fromLTWH(position.dx, position.dy, 180, 52);

  final ChatMessage message;
  @override
  final Offset position;
  @override
  Rect bounds;

  @override
  bool get hasMeasuredBounds => true;

  @override
  void updateBounds(Rect newBounds) {
    bounds = newBounds;
  }

  @override
  String get id => message.id;

  @override
  WorldObjectKind get kind => switch (message.kind) {
    MessageKind.emoji => WorldObjectKind.emojiToy,
    MessageKind.gif => WorldObjectKind.animatedToy,
    MessageKind.text => WorldObjectKind.platform,
  };

  @override
  PetState interactionFor(PetEvent event) => switch (kind) {
    WorldObjectKind.platform => PetState.jump,
    WorldObjectKind.emojiToy => PetState.pounce,
    WorldObjectKind.animatedToy => PetState.observe,
  };
}
