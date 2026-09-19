import 'dart:ui';

import '../../chat/domain/chat_message.dart';
import 'pet_message_content_kind.dart';
import 'pet_message_target.dart';
import 'pet_message_target_factory.dart';
import 'pet_world.dart';

/// Compatibility adapter for callers that still construct bubble targets.
class PetMessageBubbleTarget implements PetBoundedInteractable {
  PetMessageBubbleTarget({required this.message, Rect? bounds})
    : _target = PetMessageTargetFactory.fromDomainMessage(message) {
    if (bounds != null) {
      _target.markMeasuredBounds(bounds);
    }
  }

  final ChatMessage message;
  final PetMessageTarget _target;

  PetMessageTargetData get data => _target;

  PetNormalizedContentKind get contentKind => _target.contentKind;

  Object? get payload => _target.payload;

  String get messageText => _target.messageText;

  @override
  Rect get bounds => _target.bounds;

  @override
  bool get hasMeasuredBounds => _target.hasMeasuredBounds;

  @override
  String get id => _target.id;

  @override
  Offset get position => _target.position;

  @override
  WorldObjectKind get kind => _target.kind;

  @override
  PetState interactionFor(PetEvent event) => _target.interactionFor(event);

  @override
  void updateBounds(Rect newBounds) {
    _target.markMeasuredBounds(newBounds);
  }
}
