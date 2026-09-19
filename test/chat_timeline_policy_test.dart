import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/chat/presentation/chat_timeline_policy.dart';

void main() {
  test('near bottom includes configured reading threshold', () {
    expect(
      ChatTimelinePolicy.isNearBottom(pixels: 780, maxScrollExtent: 860),
      isTrue,
    );
    expect(
      ChatTimelinePolicy.isNearBottom(pixels: 600, maxScrollExtent: 860),
      isFalse,
    );
  });

  test('new incoming message follows only when user is near bottom', () {
    expect(
      ChatTimelinePolicy.shouldFollowNewMessage(isNearBottom: true),
      isTrue,
    );
    expect(
      ChatTimelinePolicy.shouldFollowNewMessage(isNearBottom: false),
      isFalse,
    );
  });
}
