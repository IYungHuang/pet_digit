import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/pet/domain/pet_behavior_catalog.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_runtime.dart';

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
}
