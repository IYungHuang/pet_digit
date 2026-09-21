// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoomMember _$RoomMemberFromJson(Map<String, dynamic> json) => _RoomMember(
  uid: json['uid'] as String,
  role: $enumDecode(_$RoomMemberRoleEnumMap, json['role']),
  active: json['active'] as bool? ?? true,
  joinedAt: const FlexibleDateTimeConverter().fromJson(json['joinedAt']),
  pets:
      (json['pets'] as List<dynamic>?)
          ?.map((e) => PetRoomSnapshot.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PetRoomSnapshot>[],
);

Map<String, dynamic> _$RoomMemberToJson(_RoomMember instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'role': _$RoomMemberRoleEnumMap[instance.role]!,
      'active': instance.active,
      'joinedAt': const FlexibleDateTimeConverter().toJson(instance.joinedAt),
      'pets': _petsToJson(instance.pets),
    };

const _$RoomMemberRoleEnumMap = {
  RoomMemberRole.owner: 'owner',
  RoomMemberRole.admin: 'admin',
  RoomMemberRole.member: 'member',
};
