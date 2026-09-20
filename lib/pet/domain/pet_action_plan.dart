import 'package:flutter/foundation.dart';

import 'pet_behavior_catalog.dart';

enum PetRuntimeAction {
  jumpToPlatform,
  chaseEmoji,
  inspectMedia,
  observeTarget,
  catPawTest,
  dogProbe,
  parrotProbe,
}

@immutable
class PetActionPlan {
  const PetActionPlan({
    required this.runtimeAction,
    required this.catalogAction,
    required this.originTargetId,
    this.payload,
    this.walkToward = false,
  });

  final PetRuntimeAction runtimeAction;
  final PetBehaviorAction catalogAction;
  final String originTargetId;
  final Object? payload;
  final bool walkToward;
}
