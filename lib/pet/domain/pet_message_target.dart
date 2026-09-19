import 'dart:ui';

import 'pet_message_content_kind.dart';
import 'pet_world.dart';

/// Normalized message data consumed by pet behavior runtime code.
abstract interface class PetMessageTargetData {
  String get id;
  WorldObjectKind get kind;
  PetNormalizedContentKind get contentKind;
  Object? get payload;
  String get messageText;
  Rect? get bounds;
  bool get hasMeasuredBounds;
}

/// One runtime interactable for every supported chat message model.
class PetMessageTarget implements PetMessageTargetData, PetBoundedInteractable {
  PetMessageTarget({
    required this.id,
    required this.kind,
    required this.contentKind,
    required this.payload,
    required this.messageText,
    this.sourceIdentity,
  });

  @override
  final String id;
  @override
  final WorldObjectKind kind;
  @override
  final PetNormalizedContentKind contentKind;
  @override
  final Object? payload;
  @override
  final String messageText;

  /// Stable domain identity across client-ID to server-ID acknowledgement.
  /// Legacy and standalone targets reconcile by canonical [id].
  final ({String roomId, String clientId})? sourceIdentity;

  Rect? _measuredBounds;

  /// Zero is only a compatibility geometry fallback; readiness is explicit.
  @override
  Rect get bounds => _measuredBounds ?? Rect.zero;

  @override
  bool get hasMeasuredBounds => _measuredBounds != null;

  @override
  Offset get position => bounds.topLeft;

  /// Records layout geometry and enables position-dependent pet behavior.
  void markMeasuredBounds(Rect bounds) {
    _measuredBounds = bounds;
  }

  @override
  void updateBounds(Rect newBounds) {
    markMeasuredBounds(newBounds);
  }

  @override
  PetState interactionFor(PetEvent event) => switch (kind) {
    WorldObjectKind.platform => PetState.jump,
    WorldObjectKind.emojiToy => PetState.pounce,
    WorldObjectKind.animatedToy => PetState.observe,
  };
}
