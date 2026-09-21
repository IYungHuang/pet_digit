import 'package:freezed_annotation/freezed_annotation.dart';

import '../../common/domain/datetime_json_converter.dart';

part 'room_summary.freezed.dart';
part 'room_summary.g.dart';

enum RoomType {
  @JsonValue('direct')
  direct,
  @JsonValue('group')
  group,
}

@freezed
abstract class RoomSummary with _$RoomSummary {
  const factory RoomSummary({
    required String roomId,
    required RoomType type,
    required String name,
    String? avatarUrl,
    @Default(0) int unreadCount,
    @Default(true) bool active,
    @FlexibleDateTimeConverter() required DateTime updatedAt,
    String? lastMessageText,
    String? lastMessageSenderId,
    @FlexibleNullableDateTimeConverter() DateTime? lastMessageAt,
  }) = _RoomSummary;

  factory RoomSummary.fromJson(Map<String, dynamic> json) =>
      _$RoomSummaryFromJson(json);
}
