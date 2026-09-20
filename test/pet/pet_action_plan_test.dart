import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/pet/domain/pet_action_plan.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_catalog.dart';

void main() {
  test('plan retains immutable command metadata only', () {
    const payload = <String, Object?>{'emoji': '🧶'};
    const plan = PetActionPlan(
      runtimeAction: PetRuntimeAction.chaseEmoji,
      catalogAction: PetBehaviorAction.runChase,
      originTargetId: 'message-1',
      payload: payload,
      walkToward: true,
    );

    expect(plan.runtimeAction, PetRuntimeAction.chaseEmoji);
    expect(plan.catalogAction, PetBehaviorAction.runChase);
    expect(plan.originTargetId, 'message-1');
    expect(plan.payload, same(payload));
    expect(plan.walkToward, isTrue);
  });

  test('plan defaults to stationary execution without payload', () {
    const plan = PetActionPlan(
      runtimeAction: PetRuntimeAction.observeTarget,
      catalogAction: PetBehaviorAction.hidePeek,
      originTargetId: 'message-2',
    );

    expect(plan.payload, isNull);
    expect(plan.walkToward, isFalse);
  });
}
