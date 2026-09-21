// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoomSummary _$RoomSummaryFromJson(Map<String, dynamic> json) => _RoomSummary(
  roomId: json['roomId'] as String,
  type: $enumDecode(_$RoomTypeEnumMap, json['type']),
  name: json['name'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
  active: json['active'] as bool? ?? true,
  updatedAt: const FlexibleDateTimeConverter().fromJson(json['updatedAt']),
  lastMessageText: json['lastMessageText'] as String?,
  lastMessageSenderId: json['lastMessageSenderId'] as String?,
  lastMessageAt: const FlexibleNullableDateTimeConverter().fromJson(
    json['lastMessageAt'],
  ),
);

Map<String, dynamic> _$RoomSummaryToJson(_RoomSummary instance) =>
    <String, dynamic>{
      'roomId': instance.roomId,
      'type': _$RoomTypeEnumMap[instance.type]!,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
      'unreadCount': instance.unreadCount,
      'active': instance.active,
      'updatedAt': const FlexibleDateTimeConverter().toJson(instance.updatedAt),
      'lastMessageText': instance.lastMessageText,
      'lastMessageSenderId': instance.lastMessageSenderId,
      'lastMessageAt': const FlexibleNullableDateTimeConverter().toJson(
        instance.lastMessageAt,
      ),
    };

const _$RoomTypeEnumMap = {RoomType.direct: 'direct', RoomType.group: 'group'};
