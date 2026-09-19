class ChatTimelinePolicy {
  const ChatTimelinePolicy._();

  static const double defaultNearBottomThreshold = 120;

  static bool isNearBottom({
    required double pixels,
    required double maxScrollExtent,
    double threshold = defaultNearBottomThreshold,
  }) => maxScrollExtent - pixels <= threshold;

  static bool shouldFollowNewMessage({required bool isNearBottom}) =>
      isNearBottom;
}
